#!/usr/bin/env python3
"""Build a self-contained HTML report from analytics/summary.json.

Standalone step, not part of the deployed app. Run after the Node
aggregation script (analytics.js) has produced summary.json:

    node analytics/analytics.js
    python3 analytics/make_report.py

Reads summary.json (grouped by condition x wpm: n, mean accuracy %, std
dev, std error), renders three matplotlib charts as 300 DPI PNGs into
analytics_output/, then embeds them as base64 data URIs in a single
report.html alongside a styled results table and a plain-language written
briefing.
"""

import base64
import json
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

BASE_DIR = Path(__file__).resolve().parent
SUMMARY_PATH = BASE_DIR / "summary.json"
OUTPUT_DIR = BASE_DIR / "analytics_output"
REPORT_PATH = OUTPUT_DIR / "report.html"

SPEEDS = [250, 450]
CONDITIONS = ["rsvp", "time_capped_normal"]
CONDITION_LABELS = {"rsvp": "RSVP", "time_capped_normal": "Time-capped normal"}
# Same two categorical slots (blue/orange) used by the Node script's charts,
# so the two pipelines read as one visual system.
COLORS = {"rsvp": "#2a78d6", "time_capped_normal": "#eb6834"}
GAP_POSITIVE_COLOR = "#2a78d6"  # RSVP ahead
GAP_NEGATIVE_COLOR = "#e34948"  # normal ahead
INK = "#0b0b0b"
INK_SECONDARY = "#52514e"
INK_MUTED = "#898781"

Z_95 = 1.96


# ---------- load ----------


def load_summary():
    if not SUMMARY_PATH.exists():
        sys.exit(
            f"Missing {SUMMARY_PATH} — run the Node aggregation step first:\n"
            "  node analytics.js"
        )
    data = json.loads(SUMMARY_PATH.read_text())
    groups = {(g["condition"], g["wpm"]): g for g in data["groups"]}
    for cond in CONDITIONS:
        for wpm in SPEEDS:
            if (cond, wpm) not in groups:
                sys.exit(
                    f"summary.json is missing the {cond}/{wpm} group — "
                    "re-run node analytics.js to regenerate it."
                )
    return data, groups


def ci95(mean, se):
    margin = Z_95 * se
    return mean - margin, mean + margin


def ci_overlap(a, b):
    a_lo, a_hi = a
    b_lo, b_hi = b
    return not (a_hi < b_lo or b_hi < a_lo)


# ---------- charts ----------


def configure_style():
    plt.style.use("seaborn-v0_8-whitegrid")
    plt.rcParams.update(
        {
            "font.size": 13,
            "axes.titlesize": 14,
            "axes.labelsize": 13,
            "xtick.labelsize": 12,
            "ytick.labelsize": 12,
            "legend.fontsize": 12,
            "figure.dpi": 100,
        }
    )


def save(fig, name):
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUTPUT_DIR / name
    fig.tight_layout()
    fig.savefig(path, dpi=300)
    plt.close(fig)
    return path


def make_accuracy_chart(groups):
    fig, ax = plt.subplots(figsize=(9, 6))
    x = range(len(SPEEDS))
    width = 0.35

    for i, cond in enumerate(CONDITIONS):
        means = [groups[(cond, s)]["meanAccuracy"] for s in SPEEDS]
        ses = [groups[(cond, s)]["se"] for s in SPEEDS]
        offset = (i - 0.5) * width
        xs = [xi + offset for xi in x]
        ax.bar(
            xs,
            means,
            width,
            yerr=ses,
            capsize=6,
            label=CONDITION_LABELS[cond],
            color=COLORS[cond],
            edgecolor="white",
            linewidth=0.6,
            error_kw={"ecolor": INK, "elinewidth": 1.5, "capthick": 1.5},
        )
        for xi, m, se in zip(xs, means, ses):
            ax.text(xi, m + se + 2, f"{m:.1f}%", ha="center", va="bottom", fontsize=12, fontweight="bold", color=INK_SECONDARY)

    ax.set_xticks(list(x))
    ax.set_xticklabels([f"{s} wpm" for s in SPEEDS])
    ax.set_xlabel("Reading speed (words per minute)")
    ax.set_ylabel("Mean comprehension accuracy (%)")
    ax.set_title("Mean comprehension accuracy by speed and condition\n(error bars = ± standard error)")
    ax.set_ylim(0, 100)
    ax.legend(title="Condition", frameon=False, loc="upper right")
    return save(fig, "accuracy_by_condition.png")


def make_sample_size_chart(groups, low_sample_threshold):
    fig, ax = plt.subplots(figsize=(9, 6))
    x = range(len(SPEEDS))
    width = 0.35

    all_ns = [g["n"] for g in groups.values()]
    y_max = max(all_ns + [low_sample_threshold, 1]) * 1.3
    ax.set_ylim(0, y_max)

    for i, cond in enumerate(CONDITIONS):
        ns = [groups[(cond, s)]["n"] for s in SPEEDS]
        offset = (i - 0.5) * width
        xs = [xi + offset for xi in x]
        ax.bar(xs, ns, width, label=CONDITION_LABELS[cond], color=COLORS[cond], edgecolor="white", linewidth=0.6)
        for xi, n in zip(xs, ns):
            ax.text(xi, n + y_max * 0.02, str(n), ha="center", va="bottom", fontsize=12, fontweight="bold", color=INK_SECONDARY)

    # Neutral dark ink rather than an amber/orange tone — a warm threshold
    # color washed out against the orange "time-capped normal" bars.
    ax.axhline(low_sample_threshold, color=INK, linestyle="--", linewidth=1.5)
    ax.text(
        len(SPEEDS) - 1 + width,
        low_sample_threshold + y_max * 0.045,
        f"low-sample threshold (n={low_sample_threshold})",
        color=INK,
        fontsize=11,
        fontweight="bold",
        ha="right",
    )

    ax.set_xticks(list(x))
    ax.set_xticklabels([f"{s} wpm" for s in SPEEDS])
    ax.set_xlabel("Reading speed (words per minute)")
    ax.set_ylabel("Trials collected (n)")
    ax.set_title("Sample size by speed and condition")
    ax.legend(title="Condition", frameon=False, loc="upper right")
    return save(fig, "sample_size_by_group.png")


def make_gap_chart(groups):
    gaps = []
    for s in SPEEDS:
        rsvp_mean = groups[("rsvp", s)]["meanAccuracy"]
        normal_mean = groups[("time_capped_normal", s)]["meanAccuracy"]
        gaps.append(rsvp_mean - normal_mean)

    colors = [GAP_POSITIVE_COLOR if g >= 0 else GAP_NEGATIVE_COLOR for g in gaps]
    fig, ax = plt.subplots(figsize=(9, 6))
    x = list(range(len(SPEEDS)))
    ax.bar(x, gaps, width=0.5, color=colors, edgecolor="white", linewidth=0.6)

    for xi, g in zip(x, gaps):
        va = "bottom" if g >= 0 else "top"
        text_offset = 1.2 if g >= 0 else -1.2
        ax.text(xi, g + text_offset, f"{g:+.1f} pts", ha="center", va=va, fontsize=12, fontweight="bold", color=INK_SECONDARY)

    ax.axhline(0, color=INK_MUTED, linewidth=1)
    ax.set_xticks(x)
    ax.set_xticklabels([f"{s} wpm" for s in SPEEDS])
    ax.set_xlabel("Reading speed (words per minute)")
    ax.set_ylabel("Accuracy gap, RSVP minus normal (percentage points)")
    ax.set_title("RSVP vs. time-capped normal: accuracy gap by speed")
    return save(fig, "accuracy_gap.png")


# ---------- html helpers ----------


def to_data_uri(path: Path) -> str:
    encoded = base64.b64encode(path.read_bytes()).decode("ascii")
    return f"data:image/png;base64,{encoded}"


def chart_figure_html(anchor, title, path: Path, alt):
    uri = to_data_uri(path)
    return f"""
    <figure class="chart-figure">
      <img src="{uri}" alt="{alt}" width="1600" height="1000" />
      <figcaption>
        <a href="{uri}" download="{path.name}">Download image ({path.name})</a>
      </figcaption>
    </figure>
    """


def fmt(value, digits=1):
    return f"{value:.{digits}f}"


# ---------- pooled totals row ----------


def pooled_totals(groups):
    all_groups = list(groups.values())
    total_n = sum(g["n"] for g in all_groups)
    weighted_mean = sum(g["n"] * g["meanAccuracy"] for g in all_groups) / total_n

    # Pooled within-group standard deviation (assumes similar within-group
    # variance across groups; does not add between-group variance). Labeled
    # "pooled" in the report so it isn't read as a simple grand SD.
    dof = sum(max(g["n"] - 1, 0) for g in all_groups)
    if dof > 0:
        pooled_var = sum(max(g["n"] - 1, 0) * g["stddev"] ** 2 for g in all_groups) / dof
        pooled_sd = pooled_var ** 0.5
    else:
        pooled_sd = 0.0
    pooled_se = pooled_sd / (total_n ** 0.5) if total_n else 0.0

    return {"n": total_n, "meanAccuracy": weighted_mean, "stddev": pooled_sd, "se": pooled_se}


# ---------- written briefing ----------


def group_explanation(cond_label, wpm, g, low_sample_threshold):
    n, mean, sd, se = g["n"], g["meanAccuracy"], g["stddev"], g["se"]
    lo, hi = ci95(mean, se)
    low_sample_note = ""
    if n < low_sample_threshold:
        low_sample_note = f"""
        <p class="low-sample-warning">
          <strong>Low sample warning:</strong> only {n} trial{'s' if n != 1 else ''} were collected for this
          group, below the {low_sample_threshold}-trial threshold this report treats as a minimum for a
          stable estimate. With so few trials, a single unusually good or bad participant can shift the mean
          substantially, and the standard error above is likely an underestimate of how much this number
          would move if more data were collected.
        </p>
        """
    return f"""
    <div class="group-card">
      <h3 id="group-{cond_label.lower().replace(' ', '-')}-{wpm}">{cond_label} &middot; {wpm} wpm</h3>
      <p>
        <strong>n = {n}</strong> means {n} completed trial{'s' if n != 1 else ''} contributed to this group's numbers.
        More trials generally make the estimate below more trustworthy.
      </p>
      <p>
        <strong>Mean accuracy = {fmt(mean)}%</strong> is the average comprehension-quiz score across those
        {n} trial{'s' if n != 1 else ''} &mdash; the single best guess at "typical" performance in this condition.
      </p>
      <p>
        <strong>Standard deviation = {fmt(sd)}</strong> describes how spread out individual trial scores were
        around that average. A small standard deviation means most trials scored close to {fmt(mean)}%; a large
        one means performance varied a lot from trial to trial.
      </p>
      <p>
        <strong>Standard error = {fmt(se)}</strong> is different from standard deviation: it estimates how much
        the <em>mean itself</em> would likely shift if this experiment were repeated with a fresh sample of
        trials. It shrinks as n grows, which is why small groups get a wide standard error even if individual
        scores weren't wildly spread out.
      </p>
      <p>
        <strong>95% CI = [{fmt(lo)}%, {fmt(hi)}%]</strong> is the range this report is 95% confident the true
        average accuracy falls within, given this sample. A narrow interval is a precise estimate; a wide one
        (as with small n) means the true average could plausibly be quite different from {fmt(mean)}%.
      </p>
      {low_sample_note}
    </div>
    """


def determine_pattern_match(gap_250, gap_450, ci_250_overlap, ci_450_overlap):
    """Hypothesis under test: small/no gap at 250 wpm, larger gap at 450 wpm."""
    small_or_no_gap_250 = abs(gap_250) < 5 or ci_250_overlap
    meaningfully_larger_450 = abs(gap_450) > abs(gap_250) + 3 and not ci_450_overlap

    if small_or_no_gap_250 and meaningfully_larger_450:
        return "Yes", (
            f"The gap at 250 wpm ({gap_250:+.1f} pts) is small and/or not statistically distinguishable "
            f"from zero (confidence intervals overlap), while the gap at 450 wpm ({gap_450:+.1f} pts) is "
            "both larger in magnitude and the two conditions' confidence intervals no longer overlap. "
            "That is the pattern the hypothesis predicts."
        )
    if not small_or_no_gap_250 or abs(gap_450) < abs(gap_250):
        return "No", (
            f"The gap at 250 wpm ({gap_250:+.1f} pts) is not small/negligible, or the gap did not grow at "
            f"450 wpm ({gap_450:+.1f} pts) the way the hypothesis predicts. The observed pattern runs "
            "against the hypothesis as stated."
        )
    return "Unclear", (
        f"The gap at 450 wpm ({gap_450:+.1f} pts) is larger than at 250 wpm ({gap_250:+.1f} pts), pointing "
        "the right direction, but the confidence intervals still overlap enough (or the difference in gap "
        "size is small enough) that this sample can't distinguish the pattern from noise. More trials would "
        "sharpen this."
    )


def build_comparison_section(groups):
    rsvp_250, normal_250 = groups[("rsvp", 250)], groups[("time_capped_normal", 250)]
    rsvp_450, normal_450 = groups[("rsvp", 450)], groups[("time_capped_normal", 450)]

    gap_250 = rsvp_250["meanAccuracy"] - normal_250["meanAccuracy"]
    gap_450 = rsvp_450["meanAccuracy"] - normal_450["meanAccuracy"]

    ci_250_overlap = ci_overlap(ci95(rsvp_250["meanAccuracy"], rsvp_250["se"]), ci95(normal_250["meanAccuracy"], normal_250["se"]))
    ci_450_overlap = ci_overlap(ci95(rsvp_450["meanAccuracy"], rsvp_450["se"]), ci95(normal_450["meanAccuracy"], normal_450["se"]))

    verdict, reasoning = determine_pattern_match(gap_250, gap_450, ci_250_overlap, ci_450_overlap)

    def gap_sentence(speed, gap, overlap):
        leader = "RSVP" if gap > 0 else ("time-capped normal" if gap < 0 else "Neither condition")
        overlap_note = (
            "their confidence intervals overlap, so this sample can't say the difference is real rather than noise"
            if overlap
            else "their confidence intervals don't overlap, so this sample supports a real difference"
        )
        if gap == 0:
            return f"At {speed} wpm the two conditions scored identically on average ({overlap_note})."
        return f"At {speed} wpm, {leader} scored {abs(gap):.1f} percentage points higher on average, and {overlap_note}."

    return f"""
    <section id="comparison">
      <h2>Comparison: RSVP vs. time-capped normal</h2>
      <p>{gap_sentence(250, gap_250, ci_250_overlap)}</p>
      <p>{gap_sentence(450, gap_450, ci_450_overlap)}</p>
      <div class="verdict-box verdict-{verdict.lower()}">
        <p>
          <strong>Does this match the "small/no gap at 250 wpm, larger gap at 450 wpm" pattern predicted by
          the published literature?</strong>
        </p>
        <p class="verdict-label">{verdict}</p>
        <p>{reasoning}</p>
      </div>
      <p class="literature-note">
        Background: RSVP presents words one at a time at a fixed pace and removes the reader's ability to
        regress (re-fixate earlier words) or use peripheral preview the way normal reading allows. At slower
        speeds, normal reading's extra flexibility matters less because there's enough time either way, so the
        two methods often score similarly. As speed increases, normal reading can partially compensate by
        skimming or re-fixating on demand, while RSVP has no such fallback &mdash; comprehension research on
        rate-controlled vs. self-paced reading has generally found this asymmetry, which is the basis for the
        predicted pattern tested above. This report draws that conclusion from the numbers in summary.json,
        not from re-reading the underlying literature at run time &mdash; treat the yes/no/unclear verdict as a
        check against a stated hypothesis, not an independent literature review.
      </p>
    </section>
    """


def build_overview(groups, totals, low_sample_threshold):
    rsvp_250, normal_250 = groups[("rsvp", 250)], groups[("time_capped_normal", 250)]
    rsvp_450, normal_450 = groups[("rsvp", 450)], groups[("time_capped_normal", 450)]
    gap_250 = rsvp_250["meanAccuracy"] - normal_250["meanAccuracy"]
    gap_450 = rsvp_450["meanAccuracy"] - normal_450["meanAccuracy"]
    low_sample_groups = [f"{CONDITION_LABELS[c]} @ {w} wpm" for (c, w), g in groups.items() if g["n"] < low_sample_threshold]

    low_sample_sentence = (
        "All four groups meet the minimum sample threshold."
        if not low_sample_groups
        else "Note: " + ", ".join(low_sample_groups) + f" fell below the {low_sample_threshold}-trial threshold and should be read cautiously."
    )

    return f"""
    <section id="overview">
      <h2>Overview</h2>
      <p class="takeaway">
        Across {totals['totalSessions']} completed sessions ({totals['totalTrials']} trials total), RSVP scored
        {'higher' if gap_250 > 0 else 'lower' if gap_250 < 0 else 'the same'} than time-capped normal reading at
        250 wpm ({gap_250:+.1f} points) and
        {'higher' if gap_450 > 0 else 'lower' if gap_450 < 0 else 'the same'} at 450 wpm ({gap_450:+.1f} points).
        {low_sample_sentence}
      </p>
    </section>
    """


# ---------- table ----------


def build_table(groups, totals_row):
    rows = []
    for cond in CONDITIONS:
        for wpm in SPEEDS:
            g = groups[(cond, wpm)]
            lo, hi = ci95(g["meanAccuracy"], g["se"])
            rows.append(
                f"""
                <tr>
                  <td>{CONDITION_LABELS[cond]}</td>
                  <td>{wpm}</td>
                  <td>{g['n']}</td>
                  <td>{fmt(g['meanAccuracy'])}%</td>
                  <td>{fmt(g['stddev'])}</td>
                  <td>{fmt(g['se'])}</td>
                  <td>[{fmt(lo)}%, {fmt(hi)}%]</td>
                </tr>
                """
            )

    lo, hi = ci95(totals_row["meanAccuracy"], totals_row["se"])
    totals_html = f"""
    <tr class="totals-row">
      <td colspan="2">Total (pooled across all groups)</td>
      <td>{totals_row['n']}</td>
      <td>{fmt(totals_row['meanAccuracy'])}%</td>
      <td>{fmt(totals_row['stddev'])}</td>
      <td>{fmt(totals_row['se'])}</td>
      <td>[{fmt(lo)}%, {fmt(hi)}%]</td>
    </tr>
    """

    return f"""
    <section id="table">
      <h2>Summary table</h2>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Condition</th>
              <th>Speed (wpm)</th>
              <th>n</th>
              <th>Mean accuracy %</th>
              <th>Std dev</th>
              <th>Std error</th>
              <th>95% CI</th>
            </tr>
          </thead>
          <tbody>
            {''.join(rows)}
            {totals_html}
          </tbody>
        </table>
      </div>
      <p class="table-note">
        The totals row pools all {totals_row['n']} trials into one estimate; its standard deviation combines
        each group's within-group spread and does not include the (small) differences between group means, so
        treat it as a rough overall picture rather than a substitute for the per-group rows above.
      </p>
    </section>
    """


# ---------- assemble ----------


def build_html(data, groups):
    totals = data["totals"]
    low_sample_threshold = data.get("lowSampleThreshold", 5)
    totals_row = pooled_totals(groups)

    accuracy_path = make_accuracy_chart(groups)
    sample_size_path = make_sample_size_chart(groups, low_sample_threshold)
    gap_path = make_gap_chart(groups)

    overview_html = build_overview(groups, totals, low_sample_threshold)
    table_html = build_table(groups, totals_row)
    comparison_html = build_comparison_section(groups)

    detail_cards = []
    for cond in CONDITIONS:
        for wpm in SPEEDS:
            detail_cards.append(group_explanation(CONDITION_LABELS[cond], wpm, groups[(cond, wpm)], low_sample_threshold))

    charts_html = f"""
    <section id="charts">
      <h2>Charts</h2>
      {chart_figure_html('accuracy', 'Mean accuracy by condition', accuracy_path, 'Grouped bar chart of mean comprehension accuracy by speed and condition, with standard error bars')}
      {chart_figure_html('sample-size', 'Sample size by group', sample_size_path, 'Bar chart of trial counts per speed and condition group')}
      {chart_figure_html('gap', 'Accuracy gap', gap_path, 'Bar chart of the accuracy gap between RSVP and time-capped normal reading at each speed')}
    </section>
    """

    detail_html = f"""
    <section id="detailed-stats">
      <h2>Detailed statistics by group</h2>
      {''.join(detail_cards)}
    </section>
    """

    generated_at = data.get("generatedAt", "")

    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<title>Lab Trial Report</title>
<meta name="viewport" content="width=device-width, initial-scale=1" />
<style>
  :root {{
    --surface: #fcfcfb;
    --page: #f9f9f7;
    --ink: #0b0b0b;
    --ink-secondary: #52514e;
    --ink-muted: #898781;
    --gridline: #e1e0d9;
    --rsvp: #2a78d6;
    --normal: #eb6834;
    --warning-bg: #fff6e0;
    --warning-border: #eda100;
  }}
  * {{ box-sizing: border-box; }}
  body {{
    margin: 0;
    background: var(--page);
    color: var(--ink);
    font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
    line-height: 1.6;
  }}
  .report-wrap {{
    max-width: 900px;
    margin: 0 auto;
    padding: 0 24px 80px;
  }}
  header.masthead {{
    padding: 48px 0 24px;
  }}
  header.masthead h1 {{
    margin: 0 0 8px;
    font-size: 30px;
  }}
  header.masthead .meta {{
    color: var(--ink-muted);
    font-size: 14px;
  }}
  nav.mini-nav {{
    position: sticky;
    top: 0;
    z-index: 10;
    background: rgba(252, 252, 251, 0.92);
    backdrop-filter: blur(6px);
    border-bottom: 1px solid var(--gridline);
    padding: 12px 0;
    margin-bottom: 16px;
  }}
  nav.mini-nav .nav-inner {{
    max-width: 900px;
    margin: 0 auto;
    padding: 0 24px;
    display: flex;
    gap: 20px;
    flex-wrap: wrap;
  }}
  nav.mini-nav a {{
    color: var(--ink-secondary);
    text-decoration: none;
    font-size: 14px;
    font-weight: 600;
  }}
  nav.mini-nav a:hover {{
    color: var(--rsvp);
  }}
  section {{
    background: var(--surface);
    border: 1px solid var(--gridline);
    border-radius: 8px;
    padding: 32px;
    margin-bottom: 32px;
  }}
  h2 {{
    margin-top: 0;
    font-size: 22px;
    border-bottom: 1px solid var(--gridline);
    padding-bottom: 12px;
  }}
  h3 {{
    font-size: 18px;
    margin-bottom: 8px;
  }}
  .takeaway {{
    font-size: 17px;
  }}
  .chart-figure {{
    margin: 0 0 40px;
    text-align: center;
  }}
  .chart-figure:last-child {{
    margin-bottom: 0;
  }}
  .chart-figure img {{
    max-width: 100%;
    height: auto;
    border: 1px solid var(--gridline);
    border-radius: 6px;
  }}
  .chart-figure figcaption {{
    margin-top: 8px;
    font-size: 13px;
  }}
  .chart-figure figcaption a {{
    color: var(--rsvp);
    text-decoration: none;
  }}
  .chart-figure figcaption a:hover {{
    text-decoration: underline;
  }}
  .table-wrap {{
    overflow-x: auto;
  }}
  table {{
    width: 100%;
    border-collapse: collapse;
    font-size: 14px;
  }}
  th, td {{
    text-align: left;
    padding: 10px 12px;
    border-bottom: 1px solid var(--gridline);
    white-space: nowrap;
  }}
  th {{
    color: var(--ink-secondary);
    font-weight: 600;
    border-bottom: 2px solid var(--gridline);
  }}
  tbody tr:nth-child(odd) {{
    background: rgba(11, 11, 11, 0.02);
  }}
  tr.totals-row {{
    font-weight: 600;
    border-top: 2px solid var(--gridline);
  }}
  .table-note {{
    color: var(--ink-muted);
    font-size: 13px;
    margin-top: 16px;
    margin-bottom: 0;
  }}
  .group-card {{
    padding: 20px 0;
    border-bottom: 1px solid var(--gridline);
  }}
  .group-card:last-child {{
    border-bottom: none;
    padding-bottom: 0;
  }}
  .low-sample-warning {{
    background: var(--warning-bg);
    border-left: 3px solid var(--warning-border);
    padding: 12px 16px;
    border-radius: 4px;
    font-size: 14px;
  }}
  .verdict-box {{
    border: 1px solid var(--gridline);
    border-radius: 6px;
    padding: 20px;
    margin: 20px 0;
  }}
  .verdict-label {{
    font-size: 24px;
    font-weight: 700;
    margin: 4px 0 12px;
  }}
  .verdict-yes .verdict-label {{ color: #0ca30c; }}
  .verdict-no .verdict-label {{ color: #d03b3b; }}
  .verdict-unclear .verdict-label {{ color: #c98500; }}
  .literature-note {{
    color: var(--ink-secondary);
    font-size: 14px;
    margin-top: 20px;
  }}
  footer {{
    text-align: center;
    color: var(--ink-muted);
    font-size: 13px;
    padding-top: 8px;
  }}
</style>
</head>
<body>
<nav class="mini-nav">
  <div class="nav-inner">
    <a href="#overview">Overview</a>
    <a href="#charts">Charts</a>
    <a href="#table">Table</a>
    <a href="#detailed-stats">Detailed Stats</a>
    <a href="#comparison">Comparison</a>
  </div>
</nav>
<div class="report-wrap">
  <header class="masthead">
    <h1>Lab Trial Report</h1>
    <div class="meta">RSVP vs. time-capped normal reading &middot; 250 &amp; 450 wpm &middot; generated {generated_at}</div>
  </header>

  {overview_html}
  {charts_html}
  {table_html}
  {detail_html}
  {comparison_html}

  <footer>Generated by make_report.py from summary.json &middot; not part of the deployed app</footer>
</div>
</body>
</html>
"""


def main():
    configure_style()
    data, groups = load_summary()
    html = build_html(data, groups)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(html, encoding="utf-8")
    print(f"Report written to {REPORT_PATH}")
    print(f"Charts saved to {OUTPUT_DIR}/")


if __name__ == "__main__":
    main()
