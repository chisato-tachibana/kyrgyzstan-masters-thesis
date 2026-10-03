# Data

This project uses the **Life in Kyrgyzstan (LiK) Study** panel survey
(waves 2013, 2016, and 2019). The data are **not included** in this
repository because redistribution is not permitted.

The data can be obtained free of charge for research purposes from the
International Data Service Center (IDSC) of IZA:
<https://datasets.iza.org/dataset/124/life-in-kyrgyzstan-study-2010-2019>

After downloading, place the Stata files in this folder as follows:

```
data/
├── Version 2022/
│   ├── Individual/     (2019 individual files: id2, id3, id5, ...)
│   ├── Household/      (2019 household files: hh0, hh1a, hh4a, hh4b, ...)
│   └── Panelroster/    (mroster1019_short.dta)
├── LiK16_IDSC-IZA/LiK16_data_stata/
│   ├── Individual/     (2016 individual files)
│   └── Household/      (2016 household files)
└── stata/data2013/
    ├── individual/     (2013 individual files)
    └── household/      (2013 household files)
```

## DV statistics (included)

`data/dv/` contains public statistics from the National Statistical Committee
of the Kyrgyz Republic, used to build the treatment intensity in
`code/00_dv_rate.do`:

- `dv_female_victims.csv` — number of female victims of domestic violence by oblast, 2009–2023
- `population_thousands.csv` — resident population by oblast (thousands), 2012–2024

`oblast` codes follow LiK (SOATO 417xx → xx); `0` is the national total.
