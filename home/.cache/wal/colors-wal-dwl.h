/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

static const float rootcolor[]             = COLOR(0x111212ff);
static uint32_t colors[][3]                = {
	/*               fg          bg          border    */
	[SchemeNorm] = { 0xc3c3c3ff, 0x111212ff, 0x6e5959ff },
	[SchemeSel]  = { 0xc3c3c3ff, 0x57847Cff, 0x556E6Aff },
	[SchemeUrg]  = { 0xc3c3c3ff, 0x556E6Aff, 0x57847Cff },
};
