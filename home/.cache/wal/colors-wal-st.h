const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#0c0505", /* black   */
  [1] = "#535353", /* red     */
  [2] = "#5B5B5B", /* green   */
  [3] = "#676767", /* yellow  */
  [4] = "#777777", /* blue    */
  [5] = "#878787", /* magenta */
  [6] = "#969696", /* cyan    */
  [7] = "#c2c0c0", /* white   */

  /* 8 bright colors */
  [8]  = "#675555",  /* black   */
  [9]  = "#535353",  /* red     */
  [10] = "#5B5B5B", /* green   */
  [11] = "#676767", /* yellow  */
  [12] = "#777777", /* blue    */
  [13] = "#878787", /* magenta */
  [14] = "#969696", /* cyan    */
  [15] = "#c2c0c0", /* white   */

  /* special colors */
  [256] = "#0c0505", /* background */
  [257] = "#c2c0c0", /* foreground */
  [258] = "#c2c0c0",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
