static const char norm_fg[] = "#c3c3c8";
static const char norm_bg[] = "#0f1223";
static const char norm_border[] = "#5e6074";

static const char sel_fg[] = "#c3c3c8";
static const char sel_bg[] = "#7B859E";
static const char sel_border[] = "#c3c3c8";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
};
