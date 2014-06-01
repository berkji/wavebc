from numpy import linspace, zeros

def solver(I, V, f, c, U_0, U_L, L, dt, C, T,
           user_action=None, version='scalar'):
    """
    Solve u_tt = c**2*u_xx for x in [0,L] and t in [0,T],
    with u(x,0)=I(x), u_t(x,t)=V(x), u(0,t)=U_0(t), u(L,t)=U_L(t),
    and time step size dt and Courant number C.
    A Neumann condition is applied by setting U_0 or  U_L to None.
    user_action(u, x, t, n) is called at every time step with
    time t[n], the solution in array u, and corresponding to x
    coordinates in array x.
    """
    Nt = int(round(T/dt))          # No of time intervals
    t = linspace(0, Nt*dt, Nt+1)   # Mesh points in time
    dx = dt*c/float(C)             # Mesh spacing
    Nx = int(round(L/dx))          # No of space intervals
    x = linspace(0, L, Nx+1)       # Mesh points in space

    C2 = C**2; dt2 = dt*dt         # Help variables in the scheme

    u   = zeros(Nx+1)    # Solution array at new time level
    u_1 = zeros(Nx+1)    # Solution at 1 time level back
    u_2 = zeros(Nx+1)    # Solution at 2 time levels back

    Ix = range(0, Nx+1)  # Indices for x mesh
    It = range(0, Nt+1)  # Indices for t mesh

    # Load initial condition into u_1
    for i in Ix:
        u_1[i] = I(x[i])

    if user_action is not None:
        user_action(u_1, x, t, 0)

    # Special formula for the first step
    for i in Ix[1:-1]:
        u[i] = u_1[i] + dt*V(x[i]) + \
               0.5*C2*(u_1[i-1] - 2*u_1[i] + u_1[i+1]) + \
               0.5*dt2*f(x[i], t[0])

    i = Ix[0]
    if U_0 is None:
        # Set boundary values du/dn = 0
        # x=0: i-1 -> i+1 since u[i-1]=u[i+1]
        # x=L: i+1 -> i-1 since u[i+1]=u[i-1])
        ip1 = i+1
        im1 = ip1  # i-1 -> i+1
        u[i] = u_1[i] + dt*V(x[i]) + \
               0.5*C2*(u_1[im1] - 2*u_1[i] + u_1[ip1]) + \
               0.5*dt2*f(x[i], t[0])
    else:
        u[0] = U_0(dt)

    i = Ix[-1]
    if U_L is None:
        im1 = i-1
        ip1 = im1  # i+1 -> i-1
        u[i] = u_1[i] + dt*V(x[i]) + \
               0.5*C2*(u_1[im1] - 2*u_1[i] + u_1[ip1]) + \
               0.5*dt2*f(x[i], t[0])
    else:
        u[i] = U_L(dt)

    if user_action is not None:
        user_action(u, x, t, 1)

    # Update data structures for next step
    u_2[:], u_1[:] = u_1, u

    for n in It[1:-1]:
        # Update all inner points
        if version == 'scalar':
            for i in Ix[1:-1]:
                u[i] = - u_2[i] + 2*u_1[i] + \
                       C2*(u_1[i-1] - 2*u_1[i] + u_1[i+1]) + \
                       dt2*f(x[i], t[n])

        elif version == 'vectorized':
            u[1:-1] = - u_2[1:-1] + 2*u_1[1:-1] + \
                      C2*(u_1[0:-2] - 2*u_1[1:-1] + u_1[2:]) + \
                      dt2*f(x[1:-1], t[n])
        else:
            raise ValueError('version=%s' % version)

        # Insert boundary conditions
        i = Ix[0]
        if U_0 is None:
            # Set du/dx = 0
            # x=0: i-1 -> i+1 since u[i-1]=u[i+1] when du/dn=0
            # x=L: i+1 -> i-1 since u[i+1]=u[i-1] when du/dn=0
            ip1 = i+1
            im1 = ip1
            u[i] = - u_2[i] + 2*u_1[i] + \
                   C2*(u_1[im1] - 2*u_1[i] + u_1[ip1]) + \
                   dt2*f(x[i], t[n])
        else:
            u[0] = U_0(t[n+1])

        i = Ix[-1]
        if U_L is None:
            im1 = i-1
            ip1 = im1
            u[i] = - u_2[i] + 2*u_1[i] + \
                   C2*(u_1[im1] - 2*u_1[i] + u_1[ip1]) + \
                   dt2*f(x[i], t[n])
        else:
            u[i] = U_L(t[n+1])

        if user_action is not None:
            if user_action(u, x, t, n+1):
                break

        # Update data structures for next step
        u_2[:], u_1[:] = u_1, u

    return u, x, t

def viz(I, V, f, c, U_0, U_L, L, dt, C, T, umin, umax,
        version='scalar', animate=True):
    """Run solver and visualize u at each time level."""
    import scitools.std as plt, time, glob, os
    if callable(U_0):
        bc_left = 'u(0,t)=U_0(t)'
    elif U_0 is None:
        bc_left = 'du(0,t)/dx=0'
    else:
        bc_left = 'u(0,t)=0'
    if callable(U_L):
        bc_right = 'u(L,t)=U_L(t)'
    elif U_L is None:
        bc_right = 'du(L,t)/dx=0'
    else:
        bc_right = 'u(L,t)=0'

    def plot_u(u, x, t, n):
        """user_action function for solver."""
        plt.plot(x, u, 'r-',
                 xlabel='x', ylabel='u',
                 axis=[0, L, umin, umax],
                 title='t=%.3f, %s, %s' % (t[n], bc_left, bc_right))
        # Let the initial condition stay on the screen for 2
        # seconds, else insert a pause of 0.2 s between each plot
        time.sleep(2) if t[n] == 0 else time.sleep(0.2)
        plt.savefig('frame_%04d.png' % n)  # for movie making

    # Clean up old movie frames
    for filename in glob.glob('frame_*.png'):
        os.remove(filename)

    user_action = plot_u if animate else None
    u, x, t, cpu = solver(I, V, f, c, U_0, U_L, L, dt, C, T,
                          user_action, version)
    if animate:
        plt.movie('frame_*.png', encoder='html', fps=4,
                  output_file='movie.html')
        # Make other movie formats: Flash, Webm, Ogg, MP4
        codec2ext = dict(flv='flv', libx264='mp4', libvpx='webm',
                         libtheora='ogg')
        fps = 6
        filespec = 'frame_%04d.png'
        movie_program = 'avconv'  # or 'ffmpeg'
        for codec in codec2ext:
            ext = codec2ext[codec]
            cmd = '%(movie_program)s -r %(fps)d -i %(filespec)s '\
                  '-vcodec %(codec)s movie.%(ext)s' % vars()
            print cmd
            os.system(cmd)
    return cpu


def gaussian(C=1, Nx=50, animate=True, version='scalar', T=1, loc=5,
             bc_left='u=0', ic='u'):
    """Gaussian function as initial condition."""
    L = 10.
    c = 10
    sigma = 0.5

    def G(x):
        return 1/sqrt(2*pi*sigma)*exp(-0.5*((x-loc)/sigma)**2)

    u_L = 0 if bc_left == 'u=0' else None
    dt = (L/Nx)/c  # choose the stability limit with given Nx
    umax = 1.1*G(loc)
    if ic == 'u':
        # u(x,0)=Gaussian, u_t(x,0)=0
        cpu = viz(G, None, None, c, u_L, None, L, dt, C, T,
                  umin=-umax, umax=umax, version=version, animate=animate)
    else:
        # u(x,0)=0, u_t(x,0)=Gaussian
        cpu = viz(None, G, None, c, u_L, None, L, dt, C, T,
                  umin=-umax/6, umax=umax/6, version=version, animate=animate)



