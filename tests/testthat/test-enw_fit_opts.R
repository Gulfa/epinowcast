test_that("enw_fit_opts produces the expected output", {
  expect_snapshot(enw_fit_opts(sampler = NULL, adapt_delta = 0.9))
  expect_equal(enw_fit_opts(pp = TRUE, nowcast = FALSE)$data$cast, 1)
})
