library(plotly)
#--------------------Population pyramid plot------------------

get_population_pyramid_plot <- function(rv) {
  print("plot population...")
  print(head(rv$pop_input))
  data <- rv$pop_input
  # Replace "<1" with 0 and convert to numeric
  data$Age <- as.factor(gsub("<1", "0", data$Age))
  data$Male <- (-1) * data$Male
  
  # Reshape the data to long format
  long_data <- data %>% 
    pivot_longer(cols = c(Female, Male), names_to = "Gender", values_to = "count")
  
  # Create the population pyramid
  
  ggplot(long_data, aes(x = Age, y = count, fill = Gender)) +
    geom_bar(stat = "identity", position = "dodge") +
    coord_flip() +
    labs(title = "Population Pyramid", x = "Age", y = "Count") +
    scale_fill_manual(values = c("Female" = "pink", "Male" = "blue"))
  
  # return(ggplotly(plot))
}

generatePlot <- function() {
  # Example: Creating a scatterplot
  ggplot(data = mtcars, aes(x = mpg, y = disp)) +
    geom_point()
}