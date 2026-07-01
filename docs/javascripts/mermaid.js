(function () {
  var pendingRender = null;

  function renderMermaid() {
    if (!window.mermaid) return;

    mermaid.initialize({
      startOnLoad: false
    });

    mermaid.run({
      querySelector: ".mermaid:not([data-processed])"
    }).catch(function (err) {
      console.error("Mermaid rendering failed:", err);
    });
  }

  function queueRenderMermaid() {
    window.clearTimeout(pendingRender);
    pendingRender = window.setTimeout(renderMermaid, 0);
  }

  if (window.document$) {
    document$.subscribe(queueRenderMermaid);
    queueRenderMermaid();
  } else {
    window.addEventListener("load", queueRenderMermaid);
  }
})();
