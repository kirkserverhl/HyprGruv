/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

static const float rootcolor[]             = COLOR(0x0b1419ff);
static uint32_t colors[][3]                = {
	/*               fg          bg          border    */
	[SchemeNorm] = { 0xc2c4c5ff, 0x0b1419ff, 0x5a676eff },
	[SchemeSel]  = { 0xc2c4c5ff, 0x898979ff, 0x808071ff },
	[SchemeUrg]  = { 0xc2c4c5ff, 0x808071ff, 0x898979ff },
};
