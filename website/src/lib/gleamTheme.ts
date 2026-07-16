import type { ThemeRegistration } from "shiki";

// Custom Shiki theme mapping Gleam tokens onto silt's palette: aqua for
// keywords, silt for strings/numbers, faint ink for comments. Shiki needs hex,
// so these are hand-matched to the OKLCH tokens in global.css.
const ink = "#e9eeee";
const inkMuted = "#aeb9b9";
const inkFaint = "#83908f";
const aqua = "#7ed3d9";
const aquaSoft = "#9bd8b9";
const silt = "#d3a468";
const siltString = "#c1935c";

export const gleamTheme: ThemeRegistration = {
  name: "silt-gleam",
  type: "dark",
  colors: {
    "editor.background": "#00000000",
    "editor.foreground": ink,
  },
  settings: [
    { settings: { foreground: ink } },
    {
      scope: ["comment", "punctuation.definition.comment"],
      settings: { foreground: inkFaint, fontStyle: "italic" },
    },
    {
      scope: [
        "keyword",
        "keyword.control",
        "storage.type",
        "storage.modifier",
        "keyword.other",
      ],
      settings: { foreground: aqua },
    },
    {
      scope: ["string", "string.quoted", "constant.character.escape"],
      settings: { foreground: siltString },
    },
    {
      scope: ["constant.numeric", "constant.language"],
      settings: { foreground: silt },
    },
    {
      scope: [
        "entity.name.type",
        "support.type",
        "entity.name.namespace",
        "entity.name.type.module",
      ],
      settings: { foreground: aquaSoft },
    },
    {
      scope: ["entity.name.function", "support.function", "meta.function-call"],
      settings: { foreground: ink },
    },
    {
      scope: ["variable", "variable.other", "meta.definition.variable"],
      settings: { foreground: ink },
    },
    {
      scope: ["punctuation", "meta.brace", "keyword.operator"],
      settings: { foreground: inkMuted },
    },
    {
      scope: ["entity.name.function.pipe", "keyword.operator.pipe"],
      settings: { foreground: aqua },
    },
  ],
};
