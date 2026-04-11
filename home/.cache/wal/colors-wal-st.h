const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#111212", /* black   */
  [1] = "#556E6A", /* red     */
  [2] = "#57847C", /* green   */
  [3] = "#6E827C", /* yellow  */
  [4] = "#3E8585", /* blue    */
  [5] = "#488687", /* magenta */
  [6] = "#709A92", /* cyan    */
  [7] = "#c3c3c3", /* white   */

  /* 8 bright colors */
  [8]  = "#6e5959",  /* black   */
  [9]  = "#556E6A",  /* red     */
  [10] = "#57847C", /* green   */
  [11] = "#6E827C", /* yellow  */
  [12] = "#3E8585", /* blue    */
  [13] = "#488687", /* magenta */
  [14] = "#709A92", /* cyan    */
  [15] = "#c3c3c3", /* white   */

  /* special colors */
  [256] = "#111212", /* background */
  [257] = "#c3c3c3", /* foreground */
  [258] = "#c3c3c3",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
