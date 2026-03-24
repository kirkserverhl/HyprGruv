const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#101212", /* black   */
  [1] = "#3F8288", /* red     */
  [2] = "#478789", /* green   */
  [3] = "#739C8F", /* yellow  */
  [4] = "#83A598", /* blue    */
  [5] = "#9FAB96", /* magenta */
  [6] = "#CBD1A8", /* cyan    */
  [7] = "#f4f0da", /* white   */

  /* 8 bright colors */
  [8]  = "#aaa898",  /* black   */
  [9]  = "#3F8288",  /* red     */
  [10] = "#478789", /* green   */
  [11] = "#739C8F", /* yellow  */
  [12] = "#83A598", /* blue    */
  [13] = "#9FAB96", /* magenta */
  [14] = "#CBD1A8", /* cyan    */
  [15] = "#f4f0da", /* white   */

  /* special colors */
  [256] = "#101212", /* background */
  [257] = "#f4f0da", /* foreground */
  [258] = "#f4f0da",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
