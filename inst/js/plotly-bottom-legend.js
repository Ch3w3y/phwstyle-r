function(el, x, opts) {
  // plotly places a bottom legend at a fraction of the plot height and the
  // source line at a fixed offset, so the legend can sit on the axis title
  // and, once it wraps, under the source line. Stack them from what was drawn.
  var gap = 8;
  function height(node) {
    return node ? node.getBoundingClientRect().height : 0;
  }
  function annotation(i) {
    return el.querySelector(".annotation[data-index='" + i + "']");
  }
  function place() {
    var fl = el._fullLayout;
    if (!fl || !el.offsetWidth) return;
    var now = el.layout;
    var anns = now.annotations || [];
    var src = -1;
    var labels = Array.prototype.slice.call(
      el.querySelectorAll(".xaxislayer-above text, [class^='g-x'][class$='title'] text"));
    for (var k = 0; k < anns.length; k++) {
      if (anns[k].name === "phw_source") src = k;
      // ggplotly() draws a faceted chart's axis titles as annotations.
      else if (anns[k].annotationType === "axis" && anns[k].y <= 0) labels.push(annotation(k));
    }
    var plotBottom = el.getBoundingClientRect().top + fl._size.t + fl._size.h;
    var axis = 0;
    for (var i = 0; i < labels.length; i++) {
      if (!labels[i]) continue;
      var r = labels[i].getBoundingClientRect();
      if (r.height > 0) axis = Math.max(axis, r.bottom - plotBottom);
    }
    var legendTop = Math.ceil(axis + gap);
    var lh = height(el.querySelector(".legend .bg"));
    var sourceTop = Math.ceil(legendTop + (lh ? lh + gap : 0));
    var sh = src >= 0 ? height(annotation(src)) : 0;
    var mb = Math.max(opts.margin, Math.ceil((src >= 0 ? sourceTop + sh : legendTop + lh) + gap));
    var y = -legendTop / fl._size.h;
    // Text measures shift by a pixel between draws: ignore that, or it
    // redraws again.
    if (Math.abs(now.margin.b - mb) < 2 && Math.abs(now.legend.y - y) * fl._size.h < 2 &&
        (src < 0 || Math.abs(anns[src].yshift + sourceTop) < 2)) return;
    var upd = {"margin.b": mb, "legend.y": y};
    if (src >= 0) upd["annotations[" + src + "].yshift"] = -sourceTop;
    Plotly.relayout(el, upd);
  }
  el.on("plotly_afterplot", place);
  place();
}
