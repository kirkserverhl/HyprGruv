/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

static const float rootcolor[]             = COLOR(0x111313ff);
static uint32_t colors[][3]                = {
	/*               fg          bg          border    */
	[SchemeNorm] = { 0xc3c4c4ff, 0x111313ff, 0x5a6e6eff },
	[SchemeSel]  = { 0xc3c4c4ff, 0x6C7268ff, 0x656158ff },
	[SchemeUrg]  = { 0xc3c4c4ff, 0x656158ff, 0x6C7268ff },
};
