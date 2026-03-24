static const char norm_fg[] = "#f4f0da";
static const char norm_bg[] = "#101212";
static const char norm_border[] = "#aaa898";

static const char sel_fg[] = "#f4f0da";
static const char sel_bg[] = "#478789";
static const char sel_border[] = "#f4f0da";

static const char urg_fg[] = "#f4f0da";
static const char urg_bg[] = "#3F8288";
static const char urg_border[] = "#3F8288";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
