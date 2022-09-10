install.packages("wordcloud")
library(wordcloud)

word <- c("인천광역시", "강화군", "웅진군")
frequency <- c(651, 85, 61)

# wordcloud(word, frequency, colors="blue", family="AppleGothic")
wordcloud(word, frequency, colors=rainbow(length(word)), family="AppleGothic")
