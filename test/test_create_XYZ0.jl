using MagNav, Test, MAT, LinearAlgebra, Random, Statistics
Random.seed!(2)

test_file = "test_data/test_data_ins.mat"
ins_data  = matopen(test_file,"r") do file
    read(file,"ins_data")
end

test_file = "test_data/test_data_params.mat"
params    = matopen(test_file,"r") do file
    read(file,"params")
end

test_file = "test_data/test_data_traj.mat"
traj_data = matopen(test_file,"r") do file
    read(file,"traj_data")
end

ins_lat = deg2rad.(vec(ins_data["ins_lat"]))
ins_lon = deg2rad.(vec(ins_data["ins_lon"]))
ins_alt = vec(ins_data["ins_alt"])
ins_vn  = vec(ins_data["ins_vn"])
ins_ve  = vec(ins_data["ins_ve"])
ins_vd  = vec(ins_data["ins_vd"])
ins_Cnb = ins_data["ins_Cnb"]

dt             = params["dt"]
num_mc         = round(Int,params["numSims"])
init_pos_sigma = params["init_pos_sigma"]
init_alt_sigma = params["init_alt_sigma"]
init_vel_sigma = params["init_vel_sigma"]
init_att_sigma = params["init_att_sigma"]
VRW_sigma      = sqrt(params["VRW_var"])
ARW_sigma      = sqrt(params["ARW_var"])
baro_sigma     = params["baro_std"]
ha_sigma       = params["ha_sigma"]
a_hat_sigma    = params["a_hat_sigma"]
acc_sigma      = params["acc_sigma"]
gyro_sigma     = params["gyro_sigma"]
baro_tau       = params["baro_tau"]
acc_tau        = params["acc_tau"]
gyro_tau       = params["gyro_tau"]

lat      = deg2rad.(vec(traj_data["lat"]))
lon      = deg2rad.(vec(traj_data["lon"]))
alt      = vec(traj_data["alt"])
vn       = vec(traj_data["vn"])
ve       = vec(traj_data["ve"])
vd       = vec(traj_data["vd"])
fn       = vec(traj_data["fn"])
fe       = vec(traj_data["fe"])
fd       = vec(traj_data["fd"])
tt       = vec(traj_data["tt"])
Cnb      = traj_data["Cnb"]
mag_1_c  = vec(traj_data["mag_1_c"])
flux_a_x = vec(traj_data["flux_a_x"])
flux_a_y = vec(traj_data["flux_a_y"])
flux_a_z = vec(traj_data["flux_a_z"])
N        = length(lat)

cor_sigma    = params["sim"]["biasSigma"]
cor_tau      = params["sim"]["biasTau"]
cor_var      = params["meas_R"]
cor_drift    = params["sim"]["linearSlope"]
cor_perm_mag = 10.0
cor_ind_mag  = 5.0
cor_eddy_mag = 1.0

traj = MagNav.Traj(N,dt,tt,lat,lon,alt,vn,ve,vd,fn,fe,fd,Cnb)
ins  = create_ins(traj;
                  init_pos_sigma = init_pos_sigma,
                  init_alt_sigma = init_alt_sigma,
                  init_vel_sigma = init_vel_sigma,
                  init_att_sigma = init_att_sigma,
                  VRW_sigma      = VRW_sigma,
                  ARW_sigma      = ARW_sigma,
                  baro_sigma     = baro_sigma,
                  ha_sigma       = ha_sigma,
                  a_hat_sigma    = a_hat_sigma,
                  acc_sigma      = acc_sigma,
                  gyro_sigma     = gyro_sigma,
                  baro_tau       = baro_tau,
                  acc_tau        = acc_tau,
                  gyro_tau       = gyro_tau)

(mag_1_uc,_) = corrupt_mag(mag_1_c,flux_a_x,flux_a_y,flux_a_z;
                           dt           = dt,
                           cor_sigma    = cor_sigma,
                           cor_tau      = cor_tau,
                           cor_var      = cor_var,
                           cor_drift    = cor_drift,
                           cor_perm_mag = cor_perm_mag,
                           cor_ind_mag  = cor_ind_mag,
                           cor_eddy_mag = cor_eddy_mag)

@testset "Gen INS Data Tests" begin
    @test isapprox(ins.lat, ins_lat,atol=1e-3)
    @test isapprox(ins.lon, ins_lon,atol=1e-3)
    @test isapprox(ins.alt, ins_alt,atol=1000)
    @test isapprox(ins.vn , ins_vn ,atol=10)
    @test isapprox(ins.ve , ins_ve ,atol=10)
    @test isapprox(ins.vd , ins_vd ,atol=10)
    @test isapprox(ins.Cnb, ins_Cnb,atol=0.1)
end

@testset "Corrupt Measurement Tests" begin
    @test minimum(mag_1_uc .!= mag_1_c )
    @test minimum(abs.(mag_1_uc-mag_1_c) .< mean(abs.(mag_1_c)))
end