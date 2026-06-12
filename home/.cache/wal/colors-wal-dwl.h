/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

static const float rootcolor[]             = COLOR(0x0f1224ff);
static const float bordercolor[]           = COLOR(0x64677Bff);
static const float focuscolor[]            = COLOR(0x5E6175ff);
static const float urgentcolor[]           = COLOR(0x717489ff);
