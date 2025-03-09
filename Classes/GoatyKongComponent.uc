class GoatyKongComponent extends GGMutatorComponent;

var GGGoat gMe;
var GoatyKong myMut;

var SkeletalMesh mGoatyKongMesh;
var Material mGoatyKongMaterial;
var float mGoatyKongScale;

var StaticMeshComponent mBarrelMesh;
var StaticMeshComponent mExplosiveBarrelMesh;
var bool mIsBarrelReady;
var bool mUseExplosiveBarrel;
var float mThrowForce;
var SoundCue mThrowSound;
var float mBarrelReloadTime;

var bool mIsRocketBarrelActive;
var BarrelThruster	mThruster;
var ParticleSystemComponent mThrustParticle;
var SoundCue mThrustSoundCue;
var AudioComponent mAC;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	local float newCollisionRadius, newCollisionHeight, offset;

	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=GoatyKong(owningMutator);

		mBarrelMesh.SetLightEnvironment( gMe.mesh.LightEnvironment );
		mExplosiveBarrelMesh.SetLightEnvironment( gMe.mesh.LightEnvironment );
		if(!IsZero(gMe.mesh.GetBoneLocation('Spine_01')))
		{
			gMe.mesh.AttachComponent( mExplosiveBarrelMesh, 'Spine_01', vect(0.f, 0.f, 40.f));
			gMe.mesh.AttachComponent( mBarrelMesh, 'Spine_01', vect(0.f, 0.f, 40.f));
			gMe.mesh.AttachComponent(mThrustParticle, 'Spine_01', vect(0.f, 0.f, 40.f));
		}
		else if(!IsZero(gMe.mesh.GetBoneLocation('Root')))
		{
			gMe.mesh.AttachComponent( mExplosiveBarrelMesh, 'Root', vect(0.f, 0.f, 40.f));
			gMe.mesh.AttachComponent( mBarrelMesh, 'Root', vect(0.f, 0.f, 40.f));
			gMe.mesh.AttachComponent(mThrustParticle, 'Root', vect(0.f, 0.f, 40.f));
		}
		mBarrelMesh.SetHidden(true);
		mExplosiveBarrelMesh.SetHidden(true);
		mThrustParticle.SetHidden( true );
		GetNewBarrel();

		mThruster = gMe.Spawn( class'BarrelThruster' );
		mThruster.SetBase( gMe,, gMe.mesh, 'JetPackSocket' );

		gMe.SetDrawScale(mGoatyKongScale);
		gMe.mesh.SetSkeletalMesh(mGoatyKongMesh);
		gMe.mesh.SetMaterial(0, mGoatyKongMaterial);

		//Change collision box scale
		newCollisionRadius=gMe.GetCollisionRadius() * mGoatyKongScale;
		newCollisionHeight=gMe.GetCollisionHeight() * mGoatyKongScale;

		offset =  newCollisionHeight - gMe.GetCollisionHeight();
		gMe.SetCollisionSize( newCollisionRadius, newCollisionHeight );
		gMe.SetLocation( gMe.Location + vect( 0.0f, 0.0f, 1.0f ) * offset);
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if( localInput.IsKeyIsPressed( "GBA_Special", string( newKey ) ) )
		{
			ThrowBarrel();
		}

		if( localInput.IsKeyIsPressed( "GBA_AbilityAuto", string( newKey ) ) )
		{
			gMe.SetTimer(2.f, false, NameOf(ToggleRocketBarrel), self);
		}
	}
	else if( keyState == KS_Up )
	{
		if( localInput.IsKeyIsPressed( "GBA_AbilityAuto", string( newKey ) ) )
		{
			gMe.ClearTimer(NameOf(ToggleRocketBarrel), self);
		}
	}
}

function GetNewBarrel()
{
	gMe.ClearTimer(NameOf(GetNewBarrel), self);
	if(mIsBarrelReady)
		return;

	mUseExplosiveBarrel=(Rand(10) == 0);
	if(mUseExplosiveBarrel)
	{
		mExplosiveBarrelMesh.SetHidden(false);
	}
	else
	{
		mBarrelMesh.SetHidden(false);
	}
	mIsBarrelReady=true;
}

function ThrowBarrel()
{
	local KongBarrel newBarrel;
	local vector throwLocation;

	if(gMe.mIsRagdoll || !mIsBarrelReady)
		return;

	mIsBarrelReady=false;
	if(mUseExplosiveBarrel)
	{
		mExplosiveBarrelMesh.SetHidden(true);
	}
	else
	{
		mBarrelMesh.SetHidden(true);
	}
	if(mIsRocketBarrelActive)
	{
		ToggleRocketBarrel(true);
	}

	throwLocation=GetThrowLocation();
	newBarrel = gMe.Spawn(class'KongBarrel', myMut,, throwLocation,,, true);
	if(mUseExplosiveBarrel)
	{
		newBarrel.MakeExplosive(myMut.GetExplosivePhysMat());
	}
	newBarrel.CollisionComponent.WakeRigidBody();

	newBarrel.CollisionComponent.SetRBLinearVelocity(Normal(vector(gMe.Rotation)) * mThrowForce);

	gMe.PlaySound(mThrowSound);
	gMe.SetTimer(mBarrelReloadTime, false, NameOf(GetNewBarrel), self);
}

function vector GetThrowLocation()
{
	local vector throwLocation;

	gMe.mesh.GetSocketWorldLocationAndRotation( 'Demonic', throwLocation );
	if(IsZero(throwLocation))
	{
		throwLocation=gMe.Location + (Normal(vector(gMe.Rotation)) * (gMe.GetCollisionRadius() + 30.f));
	}

	return throwLocation;
}

function ToggleRocketBarrel(optional bool ignoreTest)
{
	if(!ignoreTest
	&& (!gMe.mIsRagdoll || !mUseExplosiveBarrel || !mIsBarrelReady))
		return;

	mIsRocketBarrelActive=!mIsRocketBarrelActive;
	mThrustParticle.SetHidden(!mIsRocketBarrelActive);
	mThruster.bThrustEnabled=mIsRocketBarrelActive;
	if(mIsRocketBarrelActive)
	{
		if(mAC == none || mAC.IsPendingKill())
		{
			mAC = gMe.CreateAudioComponent( mThrustSoundCue, false );
		}
		if(!mAC.IsPlaying())
		{
			mAC.Play();
		}
	}
	else
	{
		if(mAC != none && mAC.IsPlaying())
		{
			mAC.Stop();
		}
	}
}

function OnRagdoll( Actor ragdolledActor, bool isRagdoll )
{
	if(ragdolledActor == gMe && !isRagdoll)
	{
		if(mIsRocketBarrelActive)
		{
			ToggleRocketBarrel(true);
		}
	}
}

function rotator GetGlobalRotation(rotator BaseRotation, rotator LocalRotation)
{
	local vector X, Y, Z;

	GetAxes(LocalRotation, X, Y, Z);
	return OrthoRotation(X >> BaseRotation, Y >> BaseRotation, Z >> BaseRotation);
}

function TickMutatorComponent(float deltaTime)
{
	local vector camLocation;
	local rotator camRotation;
	local vector newVelocity;
	local rotator offset;

	super.TickMutatorComponent(deltaTime);

	if(mIsRocketBarrelActive)
	{
		if(gMe.Controller != none && gMe.DrivenVehicle == none)
		{
			GGPlayerControllerGame( gMe.Controller ).PlayerCamera.GetCameraViewPoint( camLocation, camRotation );
			camRotation.Pitch += 5000;//To make aiming easier
			offset.Yaw=16384;
			gMe.mesh.SetRBRotation(GetGlobalRotation(camRotation, offset));
			mThruster.SetRotation(rotator(-normal(vector(camRotation))));
			//Clamp velocity to make control easier
			newVelocity=gMe.mesh.GetRBLinearVelocity();//myMut.WorldInfo.Game.Broadcast(myMut, "newVelocity=" $ VSize(newVelocity));
			if(VSize(newVelocity) > 1000.f)
			{
				newVelocity=Normal(newVelocity) * 999.f;//Avoid being stuck in the same direction
				gMe.mesh.SetRBLinearVelocity(newVelocity);
			}
		}
		else
		{
			ToggleRocketBarrel(true);
		}
	}
}

defaultproperties
{
	mThrowSound=SoundCue'Goat_Sounds.Cue.HeadButt_Cue'
	mThrowForce=1000.f
	mBarrelReloadTime=1.f
	mGoatyKongScale=1.5f

	mGoatyKongMesh=SkeletalMesh'goat.mesh.GoatRipped'
	mGoatyKongMaterial=Material'goat.Materials.Goat_Mat_04'

	Begin Object class=StaticMeshComponent Name=StaticMeshComp1
		StaticMesh=StaticMesh'CityProps.mesh.Props_wood_barrel_A'
		Rotation=(Pitch=0, Yaw=32768, Roll=16384)
		Translation=(Y=35)
		scale=0.66f
	End Object
	mBarrelMesh=StaticMeshComp1

	Begin Object class=StaticMeshComponent Name=StaticMeshComp2
		StaticMesh=StaticMesh'Zombie_Props.mesh.TNT_wood_barrel'
		Rotation=(Pitch=0, Yaw=32768, Roll=16384)
		Translation=(Y=35)
		scale=0.66f
	End Object
	mExplosiveBarrelMesh=StaticMeshComp2

	Begin Object Class=ParticleSystemComponent Name=ParticleSystemComponent0
        Template=ParticleSystem'jetPack.Effects.JetThrust'
		bAutoActivate=true
		bResetOnDetach=true
	End Object
	mThrustParticle=ParticleSystemComponent0

	mThrustSoundCue=SoundCue'Goat_Sounds.Cue.Rocket_Loop_Cue'
}