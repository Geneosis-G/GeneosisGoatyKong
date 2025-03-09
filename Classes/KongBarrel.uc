class KongBarrel extends GGExplosiveActorContent;

var GoatyKong myMut;

var bool mIsExplosive;
var StaticMesh mExplosiveMesh;

var float mThrowSpinForce;
var vector mAngularVel;
var vector mLastVelocity;

simulated event PostBeginPlay()
{
	local rotator offsetRot;

	super.PostBeginPlay();

	myMut=GoatyKong(Owner);

	offsetRot.Yaw=16384;
	mAngularVel=Normal(vector(GetGlobalRotation(Rotation, offsetRot))) * mThrowSpinForce;
}

function string GetActorName()
{
	return mIsExplosive?"Explosive Barrel":"Barrel";
}

function rotator GetGlobalRotation(rotator BaseRotation, rotator LocalRotation)
{
	local vector X, Y, Z;

	GetAxes(LocalRotation, X, Y, Z);
	return OrthoRotation(X >> BaseRotation, Y >> BaseRotation, Z >> BaseRotation);
}

function MakeExplosive(GGPhysicalMaterialProperty newPhysProp)
{
	mIsExplosive=true;
	mApexActor=none;
	SetStaticMesh(mExplosiveMesh);
	mPhysProp = newPhysProp;
	//WorldInfo.Game.Broadcast(self, self @ "mPhysProp=" $ mPhysProp);
	if( mPhysProp != none )
	{
		mDamage 			= mPhysProp.GetExplosionDamage();
		mDamageRadius 		= mPhysProp.GetExplosionDamageRadius();
		mExplosiveMomentum  = mPhysProp.GetExplosiveMomentum();
	}
}

function bool ShouldExplode( int damageDealt, class< DamageType > damageType, vector momentum, Actor damageCauser )
{
	//if(mIsExplosive) WorldInfo.Game.Broadcast(self, self @ "mPhysProp=" $ mPhysProp);
	return mIsExplosive && super.ShouldExplode(damageDealt, damageType, momentum, damageCauser);
}

function ConvertToApex( int damageAmount, class< DamageType > damageType, vector momentum, Actor damageCauser )
{
	super.ConvertToApex(damageAmount, damageType, momentum, damageCauser);

	if(mSpawnedApexActor != none)
	{
		myMut.AddApexToDestroy(mSpawnedApexActor);
		DropRandomBananas();
	}
}

function DropRandomBananas()
{
	local int i, nbBananas;

	if(Rand(10) != 0)
		return;

	nbBananas=Rand(6)+5;
	for(i=0 ; i<nbBananas ; i++)
	{
		DropBanana();
	}
}

function DropBanana()
{
	local GGZombieGamemodeFoodPickup droppedFood;

	droppedFood = Spawn(class'GGZombieGamemodeFoodPickup',,, Location);
	droppedFood.StaticMeshComponent.SetStaticMesh(StaticMesh'Zombie_Food.Meshes.Food_Banana_02');

	droppedFood.SetPhysics( PHYS_RigidBody );
	droppedFood.StaticMeshComponent.InitRBPhys();
	droppedFood.StaticMeshComponent.BodyInstance.UpdateMassProperties( droppedFood.StaticMeshComponent.StaticMesh.BodySetup );
	droppedFood.StaticMeshComponent.WakeRigidBody();
}

simulated event Tick( float delta )
{
	super.Tick( delta );

	if(!IsZero(mAngularVel))
	{
		//WorldInfo.Game.Broadcast(self, self @ VSize(Velocity));
		if(VSize(mLastVelocity) >= 30.f && VSize(Velocity) < 30.f)
		{
			mAngularVel=vect(0, 0, 0);
		}
		StaticMeshComponent.SetRBAngularVelocity(mAngularVel);
	}

	mLastVelocity=Velocity;
}

DefaultProperties
{
	mThrowSpinForce=10000.f

	Begin Object name=StaticMeshComponent0
		StaticMesh=StaticMesh'CityProps.mesh.Props_wood_barrel_A'
		Rotation=(Pitch=0, Yaw=32768, Roll=16384)
		Translation=(Y=50)
	End Object

	mExplosiveMesh=StaticMesh'Zombie_Props.mesh.TNT_wood_barrel'
	mApexActor=GGApexDestructibleActor'AArch.Garage.arch.Barrel_Arch_01'

	bNoDelete=false
	bStatic=false
}