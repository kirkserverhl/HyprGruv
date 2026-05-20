const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#121113", /* black   */
  [1] = "#8D6159", /* red     */
  [2] = "#B8685A", /* green   */
  [3] = "#8E716C", /* yellow  */
  [4] = "#AA8778", /* blue    */
  [5] = "#867E82", /* magenta */
  [6] = "#A99993", /* cyan    */
  [7] = "#c3c3c4", /* white   */

  /* 8 bright colors */
  [8]  = "#5a5a6e",  /* black   */
  [9]  = "#8D6159",  /* red     */
  [10] = "#B8685A", /* green   */
  [11] = "#8E716C", /* yellow  */
  [12] = "#AA8778", /* blue    */
  [13] = "#867E82", /* magenta */
  [14] = "#A99993", /* cyan    */
  [15] = "#c3c3c4", /* white   */

  /* special colors */
  [256] = "#121113", /* background */
  [257] = "#c3c3c4", /* foreground */
  [258] = "#c3c3c4",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
