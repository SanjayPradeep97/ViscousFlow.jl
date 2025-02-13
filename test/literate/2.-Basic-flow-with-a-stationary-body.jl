#=
# 2. Basic flow with a stationary body
In this notebook we will simulate the flow past a stationary body.
=#

using ViscousFlow
#-
using Plots

#=
### The basic steps
From the previous notebook, we add one additional step:
* **Specify the problem**: Set the Reynolds number, the free stream, and any other problem parameters
* **Discretize**: Set up a solution domain, choose the grid Reynolds number and the critical time step limits
* **Set up bodies**: *Create the body or bodies and specify their motions, if any*
* **Construct the system structure**: Create the operators that will be used to perform the simulation
* **Initialize**: Set the initial flow field and initialize the integrator
* **Solve**: Solve the flow field
* **Examine**: Examine the results
The rest of the steps are nearly the same as in the previous example.

As before, we initialize the parameters dictionary:
=#
my_params = Dict()

#=
### Problem specification
Set the Reynolds number and free stream. We will set the free stream to be in the $x$ direction, with speed equal to 1.
=#
my_params["Re"] = 200
my_params["freestream speed"] = 1.0
my_params["freestream angle"] = 0.0

#=
### Discretize
We set the grid Re to 4.0 here to get a quicker solution, though it is generally
better to make this smaller (it defaults to 2.0).
=#
xlim = (-1.0,5.0)
ylim = (-2.0,2.0)
my_params["grid Re"] = 4.0
g = setup_grid(xlim,ylim,my_params)

#=
### Set up bodies
Here, we will set up a rectangle of half-height 0.5 and half-width 0.25
at 45 degrees angle of attack. We also need to supply the spacing between points. For this, we use
the function [`surface_point_spacing`](@ref)
=#
Δs = surface_point_spacing(g,my_params)
body = Rectangle(0.5,0.25,Δs)

#=
We place the body at a desired location and orientation with the `RigidTransform`
function. This function creates an operator `T` that acts in-place on the body:
after the operation is applied, `body` is transformed to the correct location/orientation.
=#
cent = (0.0,0.0) # center of body
α = 45π/180 # angle
T = RigidTransform(cent,α)
T(body) # transform the body to the current configuration

# Let's plot it just to make sure
plot(body,xlim=xlim,ylim=ylim)

#=
### Construct the system structure
This step is like the previous notebook, but now we also provide the body as an argument. It is important
to note that we have not provided any explicit information about the boundary conditions on our shape.
It therefore assumes that we want to enforce zero velocity on the shape. We will show another
example later in which we change this.
=#
sys = viscousflow_system(g,body,phys_params=my_params);

#=
### Initialize
Now, we initialize with zero vorticity. Note that we do this by calling
`init_sol` with no argument except for `sys` itself.
=#
u0 = init_sol(sys)

#=
and now create the integrator, with a long enough time span to hold the whole
solution history:
=#
tspan = (0.0,20.0)
integrator = init(u0,tspan,sys)

#=
### Solve
Now we are ready to solve the problem. Let's advance the solution to $t = 1$.
=#
@time step!(integrator,1.0)

#=
### Examine
Let's look at the flow field at the end of this interval
=#
plot(
plot(vorticity(integrator),sys,title="Vorticity",clim=(-15,15),levels=range(-15,15,length=30), color = :RdBu,ylim=ylim),
plot(streamfunction(integrator),sys,title="Streamlines",ylim=ylim,color = :Black),
    size=(700,300)
    )


#=
#### Compute the force history
To do this, we supply the solution history `sol`, the system `sys`, and the index
of the body (1).
=#
sol = integrator.sol;
fx, fy = force(sol,sys,1);

#=
Plot the histories. Note that we are actually plotting the drag and lift
coefficient histories here:
$$ C_D = \dfrac{F_x}{\frac{1}{2}\rho U_\infty^2 L}, \quad C_L = \dfrac{F_y}{\frac{1}{2}\rho U_\infty^2 L} $$
Since the quantities in this simulation are already scaled by $\rho$, $U_\infty$, and $L$
(because $\rho$ has been scaled out of the equations, and the free stream speed is
set to 1 and the height of the shape to 1), then we obtain these coefficients by
simply dividing by 1/2, or equivalently, by multiplying by 2:
=#
plot(
plot(sol.t,2*fx,xlim=(0,Inf),ylim=(0,4),xlabel="Convective time",ylabel="\$C_D\$",legend=:false),
plot(sol.t,2*fy,xlim=(0,Inf),ylim=(-4,4),xlabel="Convective time",ylabel="\$C_L\$",legend=:false),
    size=(800,350)
)

# The mean drag and lift coefficients (omitting the first two steps) are
meanCD = GridUtilities.mean(2*fx[3:end])
#-
meanCL = GridUtilities.mean(2*fy[3:end])
