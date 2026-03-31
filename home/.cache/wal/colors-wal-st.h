const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#111313", /* black   */
  [1] = "#656158", /* red     */
  [2] = "#6C7268", /* green   */
  [3] = "#B15A44", /* yellow  */
  [4] = "#788873", /* blue    */
  [5] = "#ABA06F", /* magenta */
  [6] = "#848881", /* cyan    */
  [7] = "#c3c4c4", /* white   */

  /* 8 bright colors */
  [8]  = "#5a6e6e",  /* black   */
  [9]  = "#656158",  /* red     */
  [10] = "#6C7268", /* green   */
  [11] = "#B15A44", /* yellow  */
  [12] = "#788873", /* blue    */
  [13] = "#ABA06F", /* magenta */
  [14] = "#848881", /* cyan    */
  [15] = "#c3c4c4", /* white   */

  /* special colors */
  [256] = "#111313", /* background */
  [257] = "#c3c4c4", /* foreground */
  [258] = "#c3c4c4",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
