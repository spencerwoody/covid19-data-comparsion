
# Comparison of data sources for COVID-19

[UT-Austin COVID-19 Modeling Consortium][consortium]

We use the New York Times data of confirmed COVID-19 deaths to make
daily updates to our [COVID-19 mortality forecasts][forecasts] for
each of the 50 states + DC.

Please see the technical review ([latest] version or [preprint]
version) for details of our model.

We have noticed some inconsistencies for mortality numbers between
various sources.  Because various modeling groups are using different
data sources for their forecasts models, we have started this repo to
compare numbers across data sources.

## Summary of data sources

(as I understand them)

- [New York Times][NYT] (NYT)
    + US data only
    + Reports *daily* cases and deaths
    + These numbers come from NYT reporters
    + These numbers are confirmed cases and deaths, and are revised as
      needed
- [Johns Hopkins University][JHU] (JHU)
    + US and international data
    + Posts daily updates of *cumulative* deaths 
    + Data are collected from government sites
    + Not entirely clear if these are entirely confirmed cases, or
      confirmed + probable

Note the big spike in daily deaths for the JHU data for New York State
for April 16-17, which I believe is due to New York City revising
their COVID-19 death numbers around April 14 to reflect suspected /
probable deaths (see [New York Times article]), whereas the NYT
appears to have strictly confirmed deaths.

## Contents

- `nyt-jhu-comparison.R` compares daily incident deaths and cumulative
  deaths from NYT and JHU, aggregated at the state level.  I restrict
  comparisons to dates after which a state has exceeded a per-capita
  mortality rate of 3 per 10 million residents.  Note that, due to
  format differences in reported data, I have to convert from daily
  deaths to cumulative deaths for NYT, and vice versa for JHU. 
- `figures/` contains figures comparing numbers of daily deaths and
  cumulative deaths between data sources for several states.  Code for
  these figures can be found in `nyt-jhu-comparison.R`.
- `data/` contains misc. data for states and other geographic aggregations. 

## Contact

Please feel free to make a pull request or contact me directly to
correct possible errors I've made. 

[Spencer Woody][mysite]  
The University of Texas at Austin  
`spencer.woody@utexas.edu`

[mysite]: https://spencerwoody.github.io/
[consortium]: https://covid-19.tacc.utexas.edu/
[forecasts]: https://covid-19.tacc.utexas.edu/projections/
[NYT]: https://github.com/nytimes/covid-19-data
[JHU]: https://github.com/CSSEGISandData/COVID-19
[latest]: https://covid-19.tacc.utexas.edu/media/filer_public/87/63/87635a46-b060-4b5b-a3a5-1b31ab8e0bc6/ut_covid-19_mortality_forecasting_model_latest.pdf
[preprint]: https://www.medrxiv.org/content/10.1101/2020.04.16.20068163v1
[New York Times article]: https://www.nytimes.com/2020/04/14/nyregion/new-york-coronavirus-deaths.html?referringSource=articleShare
