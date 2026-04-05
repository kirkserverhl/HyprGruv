/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

static const float rootcolor[]             = COLOR(0x1e1d1cff);
static uint32_t colors[][3]                = {
	/*               fg          bg          border    */
	[SchemeNorm] = { 0xc6c6c6ff, 0x1e1d1cff, 0x767660ff },
	[SchemeSel]  = { 0xc6c6c6ff, 0xA0967Fff, 0x928B78ff },
	[SchemeUrg]  = { 0xc6c6c6ff, 0x928B78ff, 0xA0967Fff },
};
