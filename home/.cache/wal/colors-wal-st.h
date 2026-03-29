const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#101212", /* black   */
  [1] = "#3F8288", /* red     */
  [2] = "#478789", /* green   */
  [3] = "#739C90", /* yellow  */
  [4] = "#83A598", /* blue    */
  [5] = "#9EAA95", /* magenta */
  [6] = "#C9D1A8", /* cyan    */
  [7] = "#c3c3c3", /* white   */

  /* 8 bright colors */
  [8]  = "#596d6d",  /* black   */
  [9]  = "#3F8288",  /* red     */
  [10] = "#478789", /* green   */
  [11] = "#739C90", /* yellow  */
  [12] = "#83A598", /* blue    */
  [13] = "#9EAA95", /* magenta */
  [14] = "#C9D1A8", /* cyan    */
  [15] = "#c3c3c3", /* white   */

  /* special colors */
  [256] = "#101212", /* background */
  [257] = "#c3c3c3", /* foreground */
  [258] = "#c3c3c3",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
