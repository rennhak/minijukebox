#!/bin/sh

ruby -r hpricot -r open-uri -r uri -e "choices = Array.new; \
Hpricot(open('http://www.winamp.com/media/radio')).search('//div[@class=box_body]//strong//a').each\
{|a| choices.push( [ a.attributes['title'], a.attributes['href'] ]) if a.attributes['href'] =~\
%r{\.pls}i; }; print \"Please choose which music to play...\n\n\"; choices.each_with_index { |l,\
i| puts i.to_s+' |'+' '*4+l[0].to_s }; print \"\nYour choice : \"; Hpricot(open(\
choices[gets.chomp!.to_i][1])).to_s.each { |l| exec \"mplayer \"+URI.extract(l,'http').to_s if l\
=~ %r{File}i };"
