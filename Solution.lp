
#const n=50.

location(L,pair(X,Y)):- init(object(node,L),value(at,pair(X,Y))).
pair(X,Y):- init(object(node,L),value(at,pair(X,Y))).
node(L):- init(object(node,L),value(at,pair(X,Y))).


%%%%%%%%%%%%        ROBOT        %%%%%%%%%%%%
robotLocation(RID,object(node,L),0):- init(object(robot,RID),value(at,pair(X,Y))), location(L,pair(X,Y)).
robot(RID):- init(object(robot,RID),value(at,pair(X,Y))).

% No robot on 2 nodes
:- robotLocation(RID,object(node,L1),T),
   robotLocation(RID,object(node,L2),T), 
   L1!=L2, node(L1),node(L2),robot(RID), T=0..n.

% No 2 robots on the same node
:- robotLocation(RID1,object(node,L1),T),robotLocation(RID2,object(node,L1),T), RID1!=RID2, node(L1),robot(RID1),robot(RID2), T=0..n.

% Robots cant swap places
:- robotLocation(RID1,object(node,L1),T), 
    robotLocation(RID1,object(node,L2),T+1), 
    robotLocation(RID2,object(node,L2),T), 
    robotLocation(RID2,object(node,L1),T+1),
    robot(RID1),robot(RID2),
    node(L1),node(L2),
     L1!=L2,
     RID1!=RID2.


%%%%%%%%%%%%        SHELF        %%%%%%%%%%%%

shelfLocation(SID,object(node,L),0):- init(object(shelf,SID),value(at,pair(X,Y))), location(L,pair(X,Y)).
shelf(SID):- init(object(shelf,SID),value(at,pair(X,Y))).

% No shelf on 2 nodes
:-shelfLocation(SID,object(node,L),T),shelfLocation(SID,object(node,L1),T),node(L),node(L1),shelf(SID),L!=L1,T=0..n.

% No shelf on 2 robots
:-shelfLocation(SID,object(robot,RID1),T),
 shelfLocation(SID,object(robot,RID2),T),
 shelf(SID),robot(RID1),robot(RID2),RID1!=RID2, T=0..n.

% No 2 shelves on the same robot
:-shelfLocation(SID1,object(robot,RID),T),
 shelfLocation(SID2,object(robot,RID),T),
 shelf(SID1),shelf(SID2),robot(RID), SID1!=SID2,T=0..n.


% No 2 shelves on the same node
:-shelfLocation(SID1,object(node,L),T),
 shelfLocation(SID2,object(node,L),T),
 shelf(SID1),shelf(SID2),node(L), SID1!=SID2,T=0..n.

% No shelf on 2 locations (robot, node)
:- shelfLocation(SID,object(node,_),T), shelfLocation(SID,object(robot,_),T).


%===================PACKING STATION=======================%


pickingStationLocation(PSID,L):- init(object(pickingStation,PSID),value(at,pair(X,Y))), init(object(node,L),value(at,pair(X,Y))).
pickingStation(PSID):- init(object(pickingStation,PSID),value(at,pair(X,Y))), init(object(node,L),value(at,pair(X,Y))).


productLocation(PRID,object(shelf,SID),productdesc(quantity,Product_Quantity),0):- init(object(product,PRID),value(on,pair(SID,Product_Quantity))).
product(PRID):- init(object(product,PRID),value(on,pair(SID,Product_Quantity))).

request(ORDER,object(node,L),orderdesc(PRID,Product_Quantity),0):- 
init(object(order,ORDER),value(pickingStation,PSID)),
init(object(order,ORDER),value(line,pair(PRID,Product_Quantity))),
pickingStationLocation(PSID,L).

order(ORDER):- init(object(order,ORDER),value(pickingStation,PSID)).

%   cond. eff: If the robot carries a shelf, then the shelf also moves by (DX,DY).
move(0,1).
move(1,0).
move(0,-1).
move(-1,0).

noRobots(ROBOTS):- ROBOTS=#count{I:init(object(robot,I),value(at,pair(X,Y)))}.
noRows(ROWS):- ROWS=#count{X:init(object(node,I),value(at,pair(X,Y)))}.
noColumns(COLUMNS):- COLUMNS=#count{Y:init(object(node,I),value(at,pair(X,Y)))}.


{movingRobot(RID,move(DX,DY),T):move(DX,DY)}1
    :- RID=1..NR, 
    noRobots(NR), 
    T=0..n-1.

:- robotLocation(RID,object(node,L),T), movingRobot(RI,move(DX,_),T), location(L,pair(OLDLOC,_)), OLDLOC+DX<1.
:- robotLocation(RID,object(node,L),T), movingRobot(RI,move(_,DY),T), location(L,pair(_,OLDLOC)), OLDLOC+DY<1.

%:- robotLocation(RID,object(node,L),T), movingRobot(RID,move(DX,DY),T), location(L,pair(X,Y)), X+DX>NC, noRows(NC).
%:- robotLocation(RID,object(node,L),T), movingRobot(RID,move(DX,DY),T), location(L,pair(X,Y)), Y+DY>NR, noColumns(NR).


% Effect of moving a robot
robotLocation(RID,object(node,L1),T+1):-
 robotLocation(RID,object(node,L),T), 
 location(L,pair(X,Y)), 
 location(L1, pair(X+DX,Y+DY)), 
 movingRobot(RID,move(DX,DY),T).

%---------------------------------------


{pickingUpShelf(RID,SID,T):shelf(SID)}1:-
 RID=1..N, noRobots(N), T=0..n-1.

% Effect of picking up a shelf
shelfLocation(SID,object(robot,RID),T+1):-
       shelfLocation(SID,object(node,Loc_Robot),T), 
       robotLocation(RID,object(node,Loc_Shelf),T),
       pickingUpShelf(RID,SID,T).

%A shelf cant be picked up by 2 robots
:- pickingUpShelf(RID1,SID,T), pickingUpShelf(RID2,SID,T),RID1!=RID2,robot(R1),robot(R2),shelf(SID).

% A robot cannot pickup a shelf if it already has one.
%different 
:- pickingUpShelf(RID,SID1,T), shelfLocation(SID2,object(robot,RID),T),SID1!=SID2.
%same
:- pickingUpShelf(RID,SID,T), shelfLocation(SID,object(robot,RID),T).

%A robot cannot pickup a shelf a shelf is already on a robot
:- pickingUpShelf(RID1,SID,T), shelfLocation(SID,object(robot,RID2),T),RID1!=RID2.

% A robot can pick up shelf only if it is on the node containing that shelf
:- pickingUpShelf(RID,SID,T), shelfLocation(SID,object(node,L),T), not robotLocation(RID,object(node,L),T). 



%%%%%%%%%%%%     PUTTING DOWN SHELF     %%%%%%%%%%%%


{puttingDownShelf(RID,SID,T):shelf(SID)}1
:- RID=1..N, noRobots(N), T=0..n-1.

%Effect of putting down a shelf
shelfLocation(SID,object(node,L),T+1):- 
    puttingDownShelf(RID,SID,T), 
    shelfLocation(SID,object(robot,RID),T),
    robotLocation(RID,object(node,L),T).


% A shelf cant be putDown by 2 robots
:- puttingDownShelf(RID1,SID,T), puttingDownShelf(RID2,SID,T), RID1!=RID2,robot(R1),robot(R2),shelf(SID).

% A robot can put down a shelf only if it has one.
:- puttingDownShelf(RID,SID,T),  not shelfLocation(SID,object(robot,RID),T).


%===================================================



{deliver(RID,ORDER,deliverdesc(SID,PRID,Delivered_Quantity),T):
    request(ORDER,object(node,L),
    orderdesc(PRID,OQ),T), 
    productLocation(PRID,object(shelf,SID),
    productdesc(quantity,Product_Quantity),T), 
    Delivered_Quantity=1..Product_Quantity}1:-
    RID=1..N, noRobots(N), T=0..n-1.



%Effect of delivering a product
request(ORDER,object(node,L),orderdesc(PRID,Left_Order-Delivered_Quantity),T+1):- 
deliver(RID,ORDER,deliverdesc(SID,PRID,Delivered_Quantity),T), 
request(ORDER,object(node,L),
orderdesc(PRID,Left_Order),T).

productLocation(PRID,object(shelf,SID),productdesc(quantity,Product_Quantity-Delivered_Quantity),T+1):- 
deliver(RID,ORDER,deliverdesc(SID,PRID,Delivered_Quantity),T), 
productLocation(PRID,object(shelf,SID),
productdesc(quantity,Product_Quantity),T).



% Can only deliver if robot is on picking station
:- deliver(RID,ORDER,deliverdesc(_,PRID,_),T), request(ORDER,object(node,L),orderdesc(PRID,_),T), not robotLocation(RID,object(node, L),T).

% Can only deliver if robot has the shelf containing product
:- deliver(RID,ORDER,deliverdesc(SID,PRID,_),T), productLocation(PRID,object(shelf,SID),productdesc(quantity,_),T), not shelfLocation(SID,object(robot,RID),T).

% Cannot deliver more quantities than the order.
:- deliver(RID,ORDER,deliverdesc(SID,PRID,Delivered_Quantity),T), request(ORDER,object(node,L),orderdesc(PRID,Order_Quantity),T), Delivered_Quantity>Order_Quantity.

% Cannot deliver more quantities than the product.
:- deliver(RID,ORDER,deliverdesc(SID,PRID,Delivered_Quantity),T), productLocation(PRID,object(shelf,SID),productdesc(quantity,Product_Quantity),T), Delivered_Quantity>Product_Quantity.


%-------------------------------------


highway(H):- init(object(highway,H),value(at,pair(X,Y))).
% Picking Station cannot be a highway
:- pickingStationLocation(_,H), highway(H).
% Shelf cannot be on a highway.
:- shelfLocation(SID,object(node,H),_), highway(H).
% A robot cannot putdown a shelf on a highway
:- puttingDownShelf(RID,SID,T), robotLocation(RID,object(node,H),T), highway(H). 



%converting them to the necessary output
occurs(object(robot,R),action(move(DX,DY)),T):-movingRobot(R,move(DX,DY),T).
occurs(object(robot,R),action(pickup),T):-pickingUpShelf(R,_,T).
occurs(object(robot,R),action(putdown),T):-puttingDownShelf(R,_,T).
occurs(object(robot,R),action(deliver(ORDER,PRID,Delivered_Quantity)),T):-
       deliver(R,ORDER,deliverdesc(SID,PRID,Delivered_Quantity),T).


%%	ONE TO ONE ACTION CHOICE
:-occurs(object(robot,RID),action(A1),T),
  occurs(object(robot,RID),action(A2),T),
      A1!=A2 ,robot(RID).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%      LAW OF INERTIA       %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%robotLocation(RID,object(node,L),T+1):-
% robotLocation(RID,object(node,L),T), 
% not movingRobot(RID,move(_,_),T), T<n.


{robotLocation(RID,object(node,L),T+1)} :-  
  robotLocation(RID,object(node,L),T), 
   T=0..n-1.
1{robotLocation(RID,object(node,L),0):robot(RID),node(L)}1 
     :- robot(RID).
:- not 1{robotLocation(RID,object(node,L),T)}1, robot(RID), T = 1..n.


%_________%

shelfLocation(SID,object(node,L),T+1):-
shelfLocation(SID,object(node,L),T), 
not pickingUpShelf(_,SID,T),T<n.

1{shelfLocation(SID,object(node,L),0):shelf(SID),node(L)}1 
    :- shelf(SID).
{pickingUpShelf(RID,SID,T)} :- shelf(SID),robot(RID), T = 0..n-1.



shelfLocation(SID,object(robot,RID),T+1):-
shelfLocation(SID,object(robot,RID),T), 
not puttingDownShelf(RID,SID,T), T<n.
{puttingDownShelf(RID,SID,T)} :- shelf(SID),robot(RID), T = 0..n-1.



%request(ORDER,object(node,L),orderdesc(PRID,Left_Order),T+1)
%:- 
%request(ORDER,object(node,L),orderdesc(PRID,Left_Order),T), 
%productLocation(PRID,object(shelf,SID),productdesc(quantity,Product_Quantity),T), 
%not deliver(_,ORDER,deliverdesc(SID,PRID,_),T), T<n.


{request(ORDER,object(node,L),orderdesc(PRID,Left_Order),T+1)} :-  
   request(ORDER,object(node,L),orderdesc(PRID,Left_Order),T), 
   productLocation(PRID,object(shelf,SID),productdesc(quantity,Product_Quantity),T), 
  % not deliver(_,ORDER,deliverdesc(SID,PRID,_),T),
   T=0..n-1.

%1{request(ORDER,object(node,L),orderdesc(PRID,Left_Order),0):
%   order(ORDER),
%   node(L),
 %  product(PRID),
 % productLocation(PRID,object(shelf,SID),
 %   productdesc(quantity,Product_Quantity),T),
  %   Left_Order=1..Product_Quantity}1 
  %  :- 
  %  order(ORDER).

%:- not 1{ request(ORDER,object(node,L),orderdesc(PRID,Left_Order),T)}1, order(ORDER), T = 1..n.



{productLocation(PRID,object(shelf,SID),productdesc(quantity,Product_Quantity),T+1)}
:-
productLocation(PRID,object(shelf,SID),productdesc(quantity,Product_Quantity),T),
   T=0..n-1.




% Goal state
:- not request(ORDER,object(node,_),orderdesc(PRID,0),T), 
       request(ORDER,object(node,_),orderdesc(PRID,_),0),
       T=n.

#minimize{1,ROBOT,ACTION,T:occurs(ROBOT,ACTION,T)}.



init(object(node,1),value(at,pair(1,1))).
init(object(node,2),value(at,pair(2,1))).
init(object(node,3),value(at,pair(3,1))).
init(object(node,4),value(at,pair(4,1))).
init(object(node,5),value(at,pair(1,2))).
init(object(node,6),value(at,pair(2,2))).
init(object(node,7),value(at,pair(3,2))).
init(object(node,8),value(at,pair(4,2))).
init(object(node,9),value(at,pair(1,3))).
init(object(node,10),value(at,pair(2,3))).
init(object(node,11),value(at,pair(3,3))).
init(object(node,12),value(at,pair(4,3))).
init(object(node,13),value(at,pair(1,4))).
init(object(node,14),value(at,pair(2,4))).
init(object(node,15),value(at,pair(3,4))).
init(object(node,16),value(at,pair(4,4))).

init(object(highway,4),value(at,pair(4,1))).
init(object(highway,8),value(at,pair(4,2))).
init(object(highway,12),value(at,pair(4,3))).
init(object(highway,13),value(at,pair(1,4))).
init(object(highway,14),value(at,pair(2,4))).
init(object(highway,15),value(at,pair(3,4))).
init(object(highway,16),value(at,pair(4,4))).

init(object(pickingStation,1),value(at,pair(1,3))).

init(object(robot,1),value(at,pair(4,3))).
init(object(robot,2),value(at,pair(2,2))).

init(object(shelf,1),value(at,pair(3,3))).
init(object(shelf,2),value(at,pair(2,1))).
init(object(shelf,3),value(at,pair(2,3))).
init(object(shelf,4),value(at,pair(2,2))).
init(object(shelf,5),value(at,pair(3,2))).
init(object(shelf,6),value(at,pair(1,2))).

init(object(product,1),value(on,pair(3,1))).
init(object(product,2),value(on,pair(4,1))).
init(object(product,3),value(on,pair(6,4))).
init(object(product,4),value(on,pair(5,1))).
init(object(product,4),value(on,pair(6,1))).

init(object(order,1),value(pickingStation,1)).
init(object(order,1),value(line,pair(1,1))).
init(object(order,1),value(line,pair(3,4))).


%#show node/1.
%#show robot/1.
%#show shelf/1.
%#show product/1.
%#show order/1.
%#show location/2.
%#show robotLocation/3.
%#show shelfLocation/3.
%#show productLocation/4.
%#show request/4.

%#show movingRobot/3.

#show occurs/3.