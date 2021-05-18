functions {
    matrix kron_mvprod(matrix A, matrix B, matrix V) 
    {
        return transpose(A*transpose(B*V));
    }
    
  matrix gp(int N_rows, int N_columns, real[] rows_idx, real[] columns_index,
            real delta0,
            real alpha_gp1, real alpha_gp2, 
            real rho_gp1, real rho_gp2,
            matrix z1)
  {
    
    matrix[N_rows,N_columns] GP;
    
    matrix[N_rows, N_rows] K1;
    matrix[N_rows, N_rows] L_K1;
    
    matrix[N_columns, N_columns] K2;
    matrix[N_columns, N_columns] L_K2;
    
    K1 = cov_exp_quad(rows_idx, alpha_gp1, rho_gp1) + diag_matrix(rep_vector(delta0, N_rows));
    K2 = cov_exp_quad(columns_index, alpha_gp2, rho_gp2) + diag_matrix(rep_vector(delta0, N_columns));

    L_K1 = cholesky_decompose(K1);
    L_K2 = cholesky_decompose(K2);
    
    GP = kron_mvprod(L_K2, L_K1, z1);

    return(GP);
  }
}

data {
  int<lower=1> n;
  int<lower=1> m;
  real x_1[n];
  real x_2[m];
  matrix[n,m] y;
}

transformed data {
  real delta = 1e-9;
}
parameters {
  real<lower=0> rho_1;
  real<lower=0> rho_2;
  real<lower=0> alpha_1;
  real<lower=0> alpha_2;
  matrix[n,m] eta;
  real<lower=0> sigma;
}
transformed parameters {
  matrix[n,m] f = gp(n, m, x_1, x_2,
                              delta,
                              alpha_1, alpha_2, 
                              rho_1,  rho_2,
                              eta);
}

model {
  rho_1 ~ inv_gamma(5, 5);
  rho_2 ~ inv_gamma(5, 5);
  alpha_1 ~ std_normal();
  alpha_2 ~ std_normal();
  sigma ~ std_normal();
  
  for(i in 1:n){
    for(j in 1:m){
        eta[i,j] ~ std_normal();
        y[i,j] ~ normal(f[i,j], sigma);
    }
  }

  
}

generated quantities {
  matrix[n,m] y_hat;
  real log_lik[n*m];
  
  {
    int counter = 1;
    for(i in 1:n){
      for(j in 1:m){
      y_hat[i,j] = normal_rng(f[i,j], sigma);
      log_lik[counter] = normal_lpdf(y[i,j] | f[i,j], sigma);
      counter = counter + 1;
      }
    }
  }
}

