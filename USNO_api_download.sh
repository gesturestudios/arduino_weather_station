#!/bin/sh

wget http://api.usno.navy.mil/imagery/moon.png
mv moon.png /var/www/html/wp-content/uploads/moon.png
convert -resize 150x150 /var/www/html/wp-content/uploads/moon.png /var/www/html/wp-content/uploads/moon-150x150.png
convert -resize 210x210 /var/www/html/wp-content/uploads/moon.png /var/www/html/wp-content/uploads/moon-210x210.png
convert -resize 300x300 /var/www/html/wp-content/uploads/moon.png /var/www/html/wp-content/uploads/moon-300x300.png
convert -resize 768x768 /var/www/html/wp-content/uploads/moon.png /var/www/html/wp-content/uploads/moon-768x768.png

wget http://api.usno.navy.mil/imagery/earth.png
mv earth.png /var/www/html/wp-content/uploads/earth.png
convert -resize 150x150 /var/www/html/wp-content/uploads/earth.png /var/www/html/wp-content/uploads/earth-150x150.png
convert -resize 210x105 /var/www/html/wp-content/uploads/earth.png /var/www/html/wp-content/uploads/earth-210x105.png
convert -resize 300x150 /var/www/html/wp-content/uploads/earth.png /var/www/html/wp-content/uploads/earth-300x150.png
convert -resize 768x384 /var/www/html/wp-content/uploads/earth.png /var/www/html/wp-content/uploads/earth-768x384.png
convert -resize 1024x512 /var/www/html/wp-content/uploads/earth.png /var/www/html/wp-content/uploads/earth-1024x512.png
convert -resize 1536x768 /var/www/html/wp-content/uploads/earth.png /var/www/html/wp-content/uploads/earth-1536x768.png
convert -resize 1960x980 /var/www/html/wp-content/uploads/earth.png /var/www/html/wp-content/uploads/earth-1960x980.png
