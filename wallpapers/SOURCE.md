# Wallpaper source

`mountains-gray.jpg` is derived from this Unsplash photo (snowy Himalayan peaks):

https://images.unsplash.com/photo-1454496522488-7a8e488e8606

License: Unsplash License (https://unsplash.com/license): free to use, modify and
redistribute, no attribution required.

Changes: cropped to 2560x1440, converted to grayscale, darkened slightly
(`ffmpeg -vf "crop=2560:1440:0:128,format=gray,eq=brightness=-0.20:contrast=1.08:gamma=0.85"`).
