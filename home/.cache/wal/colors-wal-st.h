const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#121212", /* black   */
  [1] = "#71342A", /* red     */
  [2] = "#8F3A2B", /* green   */
  [3] = "#AD3D29", /* yellow  */
  [4] = "#CE3F27", /* blue    */
  [5] = "#964232", /* magenta */
  [6] = "#B0422E", /* cyan    */
  [7] = "#c3c3c3", /* white   */

  /* 8 bright colors */
  [8]  = "#6e5959",  /* black   */
  [9]  = "#71342A",  /* red     */
  [10] = "#8F3A2B", /* green   */
  [11] = "#AD3D29", /* yellow  */
  [12] = "#CE3F27", /* blue    */
  [13] = "#964232", /* magenta */
  [14] = "#B0422E", /* cyan    */
  [15] = "#c3c3c3", /* white   */

  /* special colors */
  [256] = "#121212", /* background */
  [257] = "#c3c3c3", /* foreground */
  [258] = "#c3c3c3",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
