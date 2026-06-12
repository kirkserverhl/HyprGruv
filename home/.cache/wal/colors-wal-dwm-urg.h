static const char norm_fg[] = "#c5c2c2";
static const char norm_bg[] = "#1a0b0b";
static const char norm_border[] = "#6f5a5a";

static const char sel_fg[] = "#c5c2c2";
static const char sel_bg[] = "#4A4F50";
static const char sel_border[] = "#c5c2c2";

static const char urg_fg[] = "#c5c2c2";
static const char urg_bg[] = "#384367";
static const char urg_border[] = "#384367";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
