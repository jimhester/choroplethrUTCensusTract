#' Get a handful of demographic variables on Utah Census Tracts from the US Census Bureau as a data.frame.
#' 
#' The data comes from the American Community Survey (ACS). The variables are: total population, percent White 
#' not Hispanic, Percent Black or African American not Hispanic, percent Asian not Hispanic,
#' percent Hispanic all races, per-capita income, median rent and median age.
#' @param endyear The end year for the survey
#' @param span The span of the survey
#' @references The choroplethr guide to Census data: http://cran.r-project.org/web/packages/choroplethr/vignettes/e-mapping-us-census-data.html
#' @importFrom acs geo.make acs.fetch geography estimate
#' @export
#' @examples
#' \dontrun{
#' df = get_ut_tract_demographics(endyear=2010, span=5)
#' colnames(df)
#'
#' # analyze the percent of people who are white not hispanic
#' # a boxplot shows the distribution
#' boxplot(df$percent_white)
#' 
#' # a choropleth map shows the location of the values in utah
#' # set the 'value' column to be the column we want to render
#' df$value = df$percent_white
#' ut_tract_choropleth(df, 
#'                     title="2010 Census Tracts\nPercent White not Hispanic", 
#'                     legend="Percent")
#'
#' # zoom into salt lake county
#' ut_tract_choropleth(df, 
#'                     title="2010 Census Tracts\nPercent White not Hispanic", 
#'                     legend="Percent",
#'                     county_zoom=49035)
#' }
get_ut_tract_demographics = function(endyear=2014, span=5)
{  
        all.ut.tracts = get_all_ut_tracts()
        race.data = acs::acs.fetch(geography    = all.ut.tracts, 
                                   table.number = "B03002", 
                                   col.names    = "pretty", 
                                   endyear      = endyear, 
                                   span         = span)
        
        # dummy to get proper regions
        dummy.df = convert_acs_obj_to_df(race.data, 1)
        
        # convert to a data.frame 
        df_race = data.frame(region                   = dummy.df$region,  
                             total_population         = as.numeric(acs::estimate(race.data[,1])),
                             white_alone_not_hispanic = as.numeric(acs::estimate(race.data[,3])),
                             black_alone_not_hispanic = as.numeric(acs::estimate(race.data[,4])),
                             asian_alone_not_hispanic = as.numeric(acs::estimate(race.data[,6])),
                             hispanic_all_races       = as.numeric(acs::estimate(race.data[,12])))
        
        df_race$region = as.character(df_race$region) # no idea why, but it's a factor before this line
        
        df_race$percent_white    = round(df_race$white_alone_not_hispanic / df_race$total_population * 100)
        df_race$percent_black    = round(df_race$black_alone_not_hispanic / df_race$total_population * 100)
        df_race$percent_asian    = round(df_race$asian_alone_not_hispanic / df_race$total_population * 100)
        df_race$percent_hispanic = round(df_race$hispanic_all_races       / df_race$total_population * 100)
        
        df_race = df_race[, c("region", "total_population", "percent_white", "percent_black", "percent_asian", "percent_hispanic")]
        
        # per capita income 
        df_income = get_ut_tract_acs_data("B19301", endyear=endyear, span=span)[[1]]   
        colnames(df_income)[[2]] = "per_capita_income"
        
        # median rent
        df_rent = get_ut_tract_acs_data("B25058", endyear=endyear, span=span)[[1]]  
        colnames(df_rent)[[2]] = "median_rent"
        
        # median age
        df_age = get_ut_tract_acs_data("B01002", endyear=endyear, span=span, column_idx=1)[[1]]  
        colnames(df_age)[[2]] = "median_age"
        
        df_demographics = merge(df_race        , df_income, all.x=TRUE)
        df_demographics = merge(df_demographics, df_rent  , all.x=TRUE)  
        df_demographics = merge(df_demographics, df_age   , all.x=TRUE)
        
        df_demographics
}