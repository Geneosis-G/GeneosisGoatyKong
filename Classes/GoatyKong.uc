class GoatyKong extends GGMutator;

var float mTimeBeforeDissapear;
var ExplosiveActorSpawnable dummyExplosiveActor;

struct BrokenApex{
	var GGApexDestructibleActor apexActor;
	var float timeBroken;
};
var array<BrokenApex> mApexToDestroy;

function GGPhysicalMaterialProperty GetExplosivePhysMat()
{
	if(dummyExplosiveActor == none || dummyExplosiveActor.bPendingDelete)
	{
		dummyExplosiveActor = Spawn(class'ExplosiveActorSpawnable',,,,,, true);
		dummyExplosiveActor.SetHidden(true);
		dummyExplosiveActor.SetPhysics(PHYS_None);
		dummyExplosiveActor.CollisionComponent=none;
	}
	//WorldInfo.Game.Broadcast(self, "dummy=" $ dummyExplosiveActor @ "PhysMat=" $ dummyExplosiveActor.GetKActorPhysMaterial() @ "PhysProp=" $ dummyExplosiveActor.GetKActorPhysMaterial().GetPhysicalMaterialProperty( class'GGPhysicalMaterialProperty' ));
	return GGPhysicalMaterialProperty( dummyExplosiveActor.GetKActorPhysMaterial().GetPhysicalMaterialProperty( class'GGPhysicalMaterialProperty' ) );
}

function AddApexToDestroy(GGApexDestructibleActor newApex)
{
	local BrokenApex newBrokenApex;

	newBrokenApex.apexActor=newApex;
	newBrokenApex.timeBroken=WorldInfo.TimeSeconds;
	if(mApexToDestroy.Find('apexActor', newApex) == INDEX_NONE)
	{
		mApexToDestroy.AddItem(newBrokenApex);
	}
}

event Tick( float deltaTime )
{
	super.Tick( deltaTime );

	SlowlyDestroyApex();
}

function SlowlyDestroyApex()
{
	local int i;
	local float timeNow;
	local GGApexDestructibleActor tmpApex;

	timeNow=WorldInfo.TimeSeconds;
	for(i=0 ; i<mApexToDestroy.Length ; i=i)
	{
		tmpApex=mApexToDestroy[i].apexActor;
		if(!tmpApex.mIsFractured)
		{
			tmpApex.Fracture(0, none, tmpApex.Location, vect(0, 0, 0), class'GGDamageTypeCollision');
		}
		if(timeNow-mApexToDestroy[i].timeBroken < mTimeBeforeDissapear)
		{
			i++;
			continue;
		}

		mApexToDestroy.Remove(i, 1);
		tmpApex.Shutdown();
		tmpApex.Destroy();
	}
}

DefaultProperties
{
	mMutatorComponentClass=class'GoatyKongComponent'

	mTimeBeforeDissapear=10.f
}