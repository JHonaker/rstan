library(rstan)

model_name <- "_8chools";
schools_code <- '
  data {
    int<lower=0> J; // number of schools 
    real y[J]; // estimated treatment effects
    real<lower=0> sigma[J]; // s.e. of effect estimates 
  }
  parameters {
    real mu; 
    real<lower=0> tau;
    real eta[J];
  }
  transformed parameters {
    real theta[J];
    for (j in 1:J)
      theta[j] <- mu + tau * eta[j];
  }
  model {
    eta ~ normal(0, 1);
    y ~ normal(theta, sigma);
  }
'
m <- stan_model(model_code = schools_code,
                model_name = model_name, 
                verbose = TRUE)  

J <- 8L 
y <- c(28,  8, -3,  7, -1,  1, 18, 12)
sigma <- c(15, 10, 16, 11,  9, 11, 10, 18)

iter <- 1000
# specify data using names 
ss1 <- sampling(m, data = c("J", "y", "sigma"), iter = iter, chains = 4, refresh = 100) 

print(ss1) 
traceplot(ss1)

dat <- c("J", "y", "sigma") 
ss <- stan(model_code = schools_code, data = dat, iter = iter, chains = 4,
           sample_file = '8schools.csv')
print(ss)
plot(ss) 


# using previous fitted objects 
ss2 <- stan(fit = ss, data = dat, iter = 2000) 
print(ss2, probs = c(0.38))
print(ss2, probs = c(0.48))
print(ss2, probs = c(0.48), use_cache = FALSE)

ss3 <- stan(fit = ss, data = dat, save_dso = FALSE) # save_dso taks no effect 
yss <- stan(model_code = schools_code, data = dat, iter = iter, chains = 4,
            sample_file = '8schools.csv', save_dso = FALSE)
save.image()

print(ss, use_cache = FALSE)
ls(ss@.MISC)
print(ss)
ls(ss@.MISC)

ss4 <- stan(fit = ss, data = dat, init = 0) 

initfun <- function(chain_id = 1) {
  cat("chain_id=", chain_id, "\n", file = 'cid.txt', append = TRUE)
  list(mu = rnorm(1), theta = rnorm(J), tau = rexp(1, chain_id))
} 
ss5 <- stan(fit = ss, data = dat, init = initfun)

cat("", file = 'cid.txt')
library(parallel)
seed <- 444
sflist1 <-
  mclapply(1:4, mc.cores = 4,
           function(i) stan(fit = ss5, seed = seed, chains = 1, chain_id = i, refresh = -1, data = dat))
ss5_1 <- sflist2stanfit(sflist1)


inits <- lapply(1:4, initfun)
ss6 <- stan(fit = ss, data = dat, init = inits) 
m6 <- get_posterior_mean(ss6)
print(m6)
print(ss6)

ss7 <- stan(fit = ss, data = dat, init = inits, chains = 4, thin = 7) 

mode <- get_cppo_mode(ss) 
get_stancode(ss, print = TRUE) 
rstan:::is_sf_valid(ss)

## print the dso 
ss@stanmodel@dso 

samples <- extract(ss) 

do.call(cat, get_adaptation_info(ss))
ss8 <- stan(fit = ss, data = dat, test_grad = TRUE)
print(ss8)
summary(ss8)
plot(ss8)
traceplot(ss8)
get_adaptation_info(ss8)
get_cppo_mode(ss8)
print(get_inits(ss8))

print(get_seed(ss8))
get_stancode(ss8, print = TRUE) 
sm8 <- get_stanmodel(ss8)
extract(ss8) 

m8 <- get_posterior_mean(ss8)
print(m8)
print(ss8)

# 
ss9 <- stan(fit = ss, data = dat,  seed = -1, chains = 1)
# seed is too big, so in config_argss, it will be turned to NA
ss10 <- stan(fit = ss, data = dat, seed = 4294967295, chains = 1, iter = 5)
get_seed(ss10) 
ss11 <- stan(fit = ss, data = dat, seed = "4294967295", chains = 1, iter = 5)

m11 <- get_posterior_mean(ss11)
print(m11)
print(ss11)

