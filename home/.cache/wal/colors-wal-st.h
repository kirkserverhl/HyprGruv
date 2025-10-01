const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#101213", /* black   */
  [1] = "#C99727", /* red     */
  [2] = "#958675", /* green   */
  [3] = "#498688", /* yellow  */
  [4] = "#A89984", /* blue    */
  [5] = "#8AA192", /* magenta */
  [6] = "#BCAD92", /* cyan    */
  [7] = "#e0d6c8", /* white   */

  /* 8 bright colors */
  [8]  = "#9c958c",  /* black   */
  [9]  = "#C99727",  /* red     */
  [10] = "#958675", /* green   */
  [11] = "#498688", /* yellow  */
  [12] = "#A89984", /* blue    */
  [13] = "#8AA192", /* magenta */
  [14] = "#BCAD92", /* cyan    */
  [15] = "#e0d6c8", /* white   */

  /* special colors */
  [256] = "#101213", /* background */
  [257] = "#e0d6c8", /* foreground */
  [258] = "#e0d6c8",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
