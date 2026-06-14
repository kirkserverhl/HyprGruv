const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#101011", /* black   */
  [1] = "#689E6B", /* red     */
  [2] = "#DB981D", /* green   */
  [3] = "#CA992E", /* yellow  */
  [4] = "#D9A124", /* blue    */
  [5] = "#938B75", /* magenta */
  [6] = "#438489", /* cyan    */
  [7] = "#c3c3c3", /* white   */

  /* 8 bright colors */
  [8]  = "#59596d",  /* black   */
  [9]  = "#689E6B",  /* red     */
  [10] = "#DB981D", /* green   */
  [11] = "#CA992E", /* yellow  */
  [12] = "#D9A124", /* blue    */
  [13] = "#938B75", /* magenta */
  [14] = "#438489", /* cyan    */
  [15] = "#c3c3c3", /* white   */

  /* special colors */
  [256] = "#101011", /* background */
  [257] = "#c3c3c3", /* foreground */
  [258] = "#c3c3c3",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
