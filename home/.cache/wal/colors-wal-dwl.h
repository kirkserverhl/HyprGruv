/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

static const float rootcolor[]             = COLOR(0x1a0b0bff);
static const float bordercolor[]           = COLOR(0x4A4F50ff);
static const float focuscolor[]            = COLOR(0x384367ff);
static const float urgentcolor[]           = COLOR(0x62696Cff);
