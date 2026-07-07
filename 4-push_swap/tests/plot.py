#!/usr/bin/env python3
# plot.py - render push_swap operation-count charts per strategy.
#
# Reads CSV "size,strategy,min,avg,max" from argv[1] or stdin.
# Prints one ASCII block per strategy.
# Saves PNG  (argv[2]) if matplotlib is installed.
# Saves HTML (argv[2] with .html extension) as fallback using Chart.js (CDN).
#
# Usage: python3 plot.py data.csv [out.png]

import sys
import json
import os
from collections import defaultdict

STRATEGIES = ["adaptive", "simple", "medium", "complex"]

COLORS = {
    "adaptive": "#2b6cb0",
    "simple":   "#c05621",
    "medium":   "#276749",
    "complex":  "#6b46c1",
}

COMPLEXITY = {
    "adaptive": "adaptativo",
    "simple":   "O(n²)",
    "medium":   "O(n√n)",
    "complex":  "O(n log n)",
}


def read_rows(path):
    rows = defaultdict(list)
    if path and path != "-":
        with open(path) as f:
            text = f.read()
    else:
        text = sys.stdin.read()
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.lower().startswith("size"):
            continue
        parts = [p.strip() for p in line.split(",")]
        if len(parts) >= 5:
            try:
                size     = int(parts[0])
                strategy = parts[1]
                mn, avg, mx = float(parts[2]), float(parts[3]), float(parts[4])
                rows[strategy].append((size, mn, avg, mx))
            except ValueError:
                continue
    return rows


def ascii_chart(rows_by_strategy):
    all_rows = [r for strat in STRATEGIES for r in rows_by_strategy.get(strat, [])]
    if not all_rows:
        print("  (sem dados)")
        return
    top   = max(r[3] for r in all_rows) or 1
    width = 50
    for strategy in STRATEGIES:
        rows = rows_by_strategy.get(strategy, [])
        if not rows:
            continue
        rows  = sorted(rows, key=lambda r: r[0])
        label = f"{strategy.upper()}  [{COMPLEXITY[strategy]}]"
        print()
        print(f"  [{label}]  barra=#avg  marcador=|max")
        print("  " + "-" * (width + 28))
        for size, mn, avg, mx in rows:
            bar_len = int(avg / top * width)
            mark    = int(mx  / top * width)
            bar     = list("." * width)
            for i in range(min(bar_len, width)):
                bar[i] = "#"
            if 0 <= mark < width:
                bar[mark] = "|"
            print(f"  n={size:<6d}  avg={avg:>9.0f}  max={mx:>9.0f}  {''.join(bar)}")
        print("  " + "-" * (width + 28))


def save_png(rows_by_strategy, out):
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except Exception:
        return False

    fig, ax = plt.subplots(figsize=(11, 6))

    for strategy in STRATEGIES:
        rows = rows_by_strategy.get(strategy, [])
        if not rows:
            continue
        rows  = sorted(rows, key=lambda r: r[0])
        sizes = [r[0] for r in rows]
        mins  = [r[1] for r in rows]
        avgs  = [r[2] for r in rows]
        maxs  = [r[3] for r in rows]
        color = COLORS[strategy]
        label = f"{strategy}  [{COMPLEXITY[strategy]}]"
        ax.plot(sizes, avgs, "o-", label=label, color=color, linewidth=1.8)
        ax.fill_between(sizes, mins, maxs, alpha=0.10, color=color)

    for n, lim, txt in [(100, 2000, "n=100 passa"), (100, 700, "n=100 excel"),
                        (500, 12000, "n=500 passa"), (500, 5500, "n=500 excel")]:
        ax.scatter([n], [lim], marker="_", s=500, color="#c53030", zorder=5)
        ax.annotate(txt, (n, lim), fontsize=7, color="#c53030",
                    xytext=(5, 3), textcoords="offset points")

    ax.set_xlabel("quantidade de numeros (n)")
    ax.set_ylabel("operacoes geradas")
    ax.set_title("push_swap — operacoes vs n por estrategia")
    ax.legend(fontsize=9)
    ax.grid(True, alpha=0.25)
    fig.tight_layout()
    fig.savefig(out, dpi=130)
    print(f"  PNG salvo em: {out}")
    return True


def save_html(rows_by_strategy, out):
    # Build datasets as pure JSON — avg line + hidden min/max lines per strategy
    datasets = []
    for strategy in STRATEGIES:
        rows = rows_by_strategy.get(strategy, [])
        if not rows:
            continue
        rows  = sorted(rows, key=lambda r: r[0])
        color = COLORS[strategy]
        label = f"{strategy} [{COMPLEXITY[strategy]}]"

        avg_pts = [{"x": r[0], "y": round(r[2], 1), "mn": r[1], "mx": r[3]}
                   for r in rows]
        min_pts = [{"x": r[0], "y": r[1]} for r in rows]
        max_pts = [{"x": r[0], "y": r[3]} for r in rows]

        datasets.append({
            "label":           label,
            "data":            avg_pts,
            "borderColor":     color,
            "backgroundColor": color + "33",
            "pointRadius":     4,
            "borderWidth":     2,
            "tension":         0.1,
        })
        datasets.append({
            "label":           f"__{strategy}_min",
            "data":            min_pts,
            "borderColor":     color + "55",
            "backgroundColor": color + "15",
            "pointRadius":     0,
            "borderWidth":     1,
            "borderDash":      [4, 4],
            "tension":         0.1,
        })
        datasets.append({
            "label":           f"__{strategy}_max",
            "data":            max_pts,
            "borderColor":     color + "55",
            "backgroundColor": color + "15",
            "pointRadius":     0,
            "borderWidth":     1,
            "borderDash":      [4, 4],
            "tension":         0.1,
        })

    datasets_json = json.dumps(datasets, ensure_ascii=False)

    html = f"""<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>push_swap — operacoes vs n</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chartjs-plugin-annotation@3/dist/chartjs-plugin-annotation.min.js"></script>
<style>
  body  {{ font-family: sans-serif; background:#f7f8fa; margin:24px; color:#1a202c; }}
  h2    {{ margin-bottom:16px; }}
  .wrap {{ position:relative; width:95%; max-width:1100px; height:520px; margin:0 auto; }}
</style>
</head>
<body>
<h2>push_swap &mdash; opera&ccedil;&otilde;es vs n por estrat&eacute;gia</h2>
<div class="wrap"><canvas id="chart"></canvas></div>
<script>
const datasets = {datasets_json};

new Chart(document.getElementById('chart'), {{
  type: 'line',
  data: {{ datasets }},
  options: {{
    parsing: false,
    responsive: true,
    maintainAspectRatio: false,
    scales: {{
      x: {{
        type: 'linear',
        title: {{ display: true, text: 'quantidade de numeros (n)' }}
      }},
      y: {{
        type: 'linear',
        title: {{ display: true, text: 'operacoes geradas' }}
      }}
    }},
    plugins: {{
      legend: {{
        labels: {{
          filter: item => !item.text.startsWith('__')
        }}
      }},
      tooltip: {{
        callbacks: {{
          label: ctx => {{
            const d = ctx.raw;
            if (d.mn !== undefined)
              return ctx.dataset.label +
                     ': avg=' + d.y.toFixed(0) +
                     '  min=' + d.mn +
                     '  max=' + d.mx;
            return ctx.dataset.label + ': ' + d.y;
          }}
        }}
      }},
      annotation: {{
        annotations: {{
          pass100: {{ type:'line', yMin:2000,  yMax:2000,  borderColor:'#c53030', borderWidth:1, borderDash:[6,3], label:{{ content:'n=100 passa (<2000)',     display:true, position:'end', color:'#c53030', font:{{size:10}} }} }},
          exc100:  {{ type:'line', yMin:700,   yMax:700,   borderColor:'#c53030', borderWidth:1, borderDash:[6,3], label:{{ content:'n=100 excelente (<700)',  display:true, position:'end', color:'#c53030', font:{{size:10}} }} }},
          pass500: {{ type:'line', yMin:12000, yMax:12000, borderColor:'#c53030', borderWidth:1, borderDash:[6,3], label:{{ content:'n=500 passa (<12000)',    display:true, position:'end', color:'#c53030', font:{{size:10}} }} }},
          exc500:  {{ type:'line', yMin:5500,  yMax:5500,  borderColor:'#c53030', borderWidth:1, borderDash:[6,3], label:{{ content:'n=500 excelente (<5500)', display:true, position:'end', color:'#c53030', font:{{size:10}} }} }}
        }}
      }}
    }}
  }}
}});
</script>
</body>
</html>
"""
    with open(out, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"  HTML salvo em: {out}")
    return True


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "-"
    out  = sys.argv[2] if len(sys.argv) > 2 else None
    rows = read_rows(path)
    ascii_chart(rows)
    if not out:
        return
    if not save_png(rows, out):
        html_out = os.path.splitext(out)[0] + ".html"
        save_html(rows, html_out)


if __name__ == "__main__":
    main()
