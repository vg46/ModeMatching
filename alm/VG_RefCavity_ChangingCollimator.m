goo = beamPath;

% Calculating target waist diameter in a cavity with mirrors of different
    % curvatures (length d = 10m, mirror curvatures R1 = infinite (flat) and R2 = ?
d = 10;
R2 = 15;  %Chosen from SVN mirror list, must be R2>d ???ask
target_waist_radius = (1550e-9/pi)^(1/2) * (d*(R2-d))^(1/4);

% Seed and target beams:
goo.seedWaist(0.605e-3,0,1550e-9); % Seed beam is input from collimator, at z=0m, lambda 1550nm (waistSize,waistPos,lambda). WaistSize is output beam radius
goo.targetWaist(target_waist_radius,2.5,1550e-9); % Beam waist input mirror of symmetric cavity, distance is z = 2.5m.

% Position of fixed optical components (m):
z45=0.3; % 45 degree mirror after collimator output - CHANGED TO MATCH BeamtoCryo DISTANCE
zM1=1.5; % First steering mirror
zM2=2; % Second steering mirror
zCav=2.5; %Distance to first cavity mirror (flat)
zCavEnd=12.5; %Distance to end of cavity mirror (curved)
zTotal = zCav; %Distance to waist in cavity, occurs on flat cavity mirror

% Add fixed optical components as components - flatMirror(Z,label)and curvedMirror(radiusOfCurvature,Z,label)
goo.addComponent(component.flatMirror(z45,'45Deg'));
goo.addComponent(component.flatMirror(zM1,'SM1'));
goo.addComponent(component.flatMirror(zM2,'SM2'));
goo.addComponent(component.flatMirror(zCav,'CavFlatMirror'));
goo.addComponent(component.curvedMirror(R2,zCavEnd,'CavEndMirror'));

zdomain = -.05:.001:zCavEnd+0.05;

% List of focal lengths of lenses available to us (SVN Laseroptik list):
    %List given in radii of curvature, divide by 2 at end for focal length
radiusofcurvatureList = [75, 100, 200, 500, 3000, 2000, 250, 750, 1000, 50, 1500, 5000, 150, 300, 350, 4000, 10000] *(1e-3);
focalLengthList = [86.4023, 114.8271, 228.5356, 569.6741, 3412.5197, 2275.3809, 285.3915, 853.9581, 1138.2425, 57.9812, 1706.8116, 5686.7974, 171.6804, 342.2477, 399.1041, 4549.6585, 11372.4921] *(1e-3); % calculated using https://www.edmundoptics.com/knowledge-center/tech-tools/focal-length/
lensList = component.lens(focalLengthList);

% 2 lenses, one between collimator output and 45 degree mirror; one between
    % 45 degree mirror and 1st steering mirror. Positions will be optimised
    % for mode overlap.   lens(focalLength,Z,label)
goo.addComponent(component.lens(0.200,0.05,'L1'));    % ask - why are those focal lengths chosen to start with?
goo.addComponent(component.lens(0.200,z45+0.2,'L2'));

figure(266)
clf
subplot(2,1,1)
hold on

[pathList,overlapList] = goo.chooseComponents(...
                'L1',lensList,[0+0.02 z45-0.02],...
                'L2',lensList.duplicate,[z45+0.02 zM1-0.02],...
                '-vt',.001);

% Cut out all solutions with modematching < 99%
pathList = pathList(overlapList >= 0.98);

% Make an array with the combined position sensitivity of the components
sensitivityList = pathList.positionSensitivity;

%Sort in increasing sensitivity
[sensitivityList,sortIndex] = sort(sensitivityList);
pathList = pathList;

% Plot the best solution
newhandle=pathList(1).plotBeamWidth(zdomain,'r');
pathList(1).plotComponents(zdomain,'r*')
pathList(1).plotBeams(zdomain,'k')

hold off
legend([newhandle],'Optimized Beam Path')
ylabel('Beam Width (m)')
xlabel('Propagation axis (m)')

subplot(2,1,2)
hold on
pathList(1).plotGouyPhase(zdomain,'wrap','b');
pathList(1).plotComponents(zdomain,'r*')
axis tight
grid on
hold off
xlabel('Propagation axis (m)')
ylabel('Gouy Phase (deg)')

% print the component list to the command window
disp(' ')
disp(' Optimized Path Component List:')
display(pathList(1).components)
