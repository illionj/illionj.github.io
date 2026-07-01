(function () {
  var pendingRender = null;

  function renderMath() {
    if (!window.MathJax || !MathJax.typesetPromise) return;

    MathJax.typesetPromise(Array.from(document.querySelectorAll(".arithmatex")))
      .catch(function (err) {
        console.error("MathJax rendering failed:", err);
      });
  }

  function queueRenderMath() {
    window.clearTimeout(pendingRender);
    pendingRender = window.setTimeout(renderMath, 0);
  }

  window.MathJax = {
    tex: {
      inlineMath: [["\\(", "\\)"]],
      displayMath: [["\\[", "\\]"]],
      processEscapes: true,
      processEnvironments: true
    },
    options: {
      ignoreHtmlClass: ".*|",
      processHtmlClass: "arithmatex"
    },
    startup: {
      ready: function () {
        MathJax.startup.defaultReady();

        if (window.document$) {
          document$.subscribe(queueRenderMath);
        }

        queueRenderMath();
      }
    }
  };
})();
