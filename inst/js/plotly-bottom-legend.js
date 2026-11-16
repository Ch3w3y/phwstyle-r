function(el, x, opts) {
  // plotly places a bottom legend at a fraction of the plot height and the
  // source line at a fixed offset, so the legend can sit on the axis title
  // and, once it wraps, under the source line. Stack them from what was drawn.
  var gap = 8;
  function height(node) {
    return node ? node.getBoundingClientRect().height : 0;
  }
  function place() {
    var fl = el._fullLayout;
    if (!fl || !el.offsetWidth) return;
    var plotBottom = el.getBoundingClientRect().top + fl._size.t + fl._size.h;
    var axis = 0;
    var labels = el.querySelectorAll(".xaxislayer-above text, [class^='g-x'][class$='title'] text");
    for (var i = 0; i < labels.length; i++) {
      var r = labels[i].getBoundingClientRect();
      if (r.height > 0) axis = Math.max(axis, r.bottom - plotBottom);
    }
    var legendTop = Math.ceil(axis + gap);
    var lh = height(el.querySelector(".legend .bg"));
    var sourceTop = Math.ceil(legendTop + (lh ? lh + gap : 0));
    var sh = opts.caption ? height(el.querySelector(".annotation[data-index='0']")) : 0;
    var mb = Math.max(opts.margin, Math.ceil((opts.caption ? sourceTop + sh : legendTop + lh) + gap));
    var y = -legendTop / fl._size.h;
    var now = el.layout;
    // Text measures shift by a pixel between draws: ignore that, or it
    // redraws again.
    if (Math.abs(now.margin.b - mb) < 2 && Math.abs(now.legend.y - y) * fl._size.h < 2 &&
        (!opts.caption || Math.abs(now.annotations[0].yshift + sourceTop) < 2)) return;
    var upd = {"margin.b": mb, "legend.y": y};
    if (opts.caption) upd["annotations[0].yshift"] = -sourceTop;
    Plotly.relayout(el, upd);
  }
  el.on("plotly_afterplot", place);
  place();
}
