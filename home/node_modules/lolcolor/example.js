const lolcolor = require('lolcolor');

const text = 'Lorem ipsum dolor sit amet';

console.log(lolcolor(text));

// OR

const { ColorBuilder } = require('lolcolor');

const builderText = 'Lorem ipsum dolor sit amet';

const colorBuilder = new ColorBuilder();

const [colorR, colorG, colorB] = colorBuilder.fromString(builderText).asRgb().butOnly64Colors().create();

console.log(`Red value:${colorR}, Green value:${colorG}, Blue value:${colorB}`);
