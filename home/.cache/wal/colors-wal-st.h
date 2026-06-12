const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#171818", /* black   */
  [1] = "#D75D0E", /* red     */
  [2] = "#C25711", /* green   */
  [3] = "#D66410", /* yellow  */
  [4] = "#D7921F", /* blue    */
  [5] = "#D79921", /* magenta */
  [6] = "#DBA436", /* cyan    */
  [7] = "#c5c5c5", /* white   */

  /* 8 bright colors */
  [8]  = "#725d5d",  /* black   */
  [9]  = "#D75D0E",  /* red     */
  [10] = "#C25711", /* green   */
  [11] = "#D66410", /* yellow  */
  [12] = "#D7921F", /* blue    */
  [13] = "#D79921", /* magenta */
  [14] = "#DBA436", /* cyan    */
  [15] = "#c5c5c5", /* white   */

  /* special colors */
  [256] = "#171818", /* background */
  [257] = "#c5c5c5", /* foreground */
  [258] = "#c5c5c5",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
