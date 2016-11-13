#!/bin/sh

for example in "pure" "effectful" "form" "pages" "xor_pages"
do
    cd $example
    elm make Main.elm --debug --output=../$example.html
    cd ..
done

