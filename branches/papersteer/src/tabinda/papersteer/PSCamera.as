﻿// ----------------------------------------------------------------------------
//
// PaperSteer - Papervision3D Port of OpenSteer
// Port by Mohammad Haseeb aka M.H.A.Q.S.
// http://www.tabinda.net
//
// OpenSteer -- Steering Behaviors for Autonomous Characters
//
// Copyright (c) 2002-2003, Sony Computer Entertainment America
// Original author: Craig Reynolds <craig_reynolds@playstation.sony.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
//
// ----------------------------------------------------------------------------

package tabinda.papersteer
{		
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.core.math.Number3D;
	import org.papervision3d.objects.DisplayObject3D;
	
	import tabinda.demo.Demo;
	
	public class PSCamera extends LocalSpace
	{
		// xxx since currently (10-21-02) the camera's Forward and Side basis
		// xxx vectors are not being set, construct a temporary local space for
		// xxx the camera view -- so as not to make the camera behave
		// xxx differently (which is to say, correctly) during mouse adjustment.
		private var ls:LocalSpace;
		
		// "look at" point, center of view
		public var Target:Vector3;

		// vehicle being tracked
		public var VehicleToTrack:IVehicle;

		// aim at predicted position of vehicleToTrack, this far into thefuture
		public var AimLeadTime:Number;
		protected var smoothNextMove:Boolean;
		protected var smoothMoveSpeed:Number;

		// current mode for this camera instance
		public var Mode:int;

		// "static" camera mode parameters
		public var FixedPosition:Vector3;
		public var FixedTarget:Vector3;
		public var FixedUp:Vector3;

		// "constant distance from vehicle" camera mode parameters
		public var FixedDistanceDistance:Number;// desired distance from it
		public var FixedDistanceVerticalOffset:Number;// fixed vertical offset from it

		// "look straight down at vehicle" camera mode parameters
		public var LookDownDistance:Number;// fixed vertical offset from it

		// "fixed local offset" camera mode parameters
		public var FixedLocalOffset:Vector3;

		// "offset POV" camera mode parameters
		public var PovOffset:Vector3;
		
		//PV3D Camera
		public var PV3DCamera:Camera3D;
		
		//[internal-use] Temporary PV3D Target Object used for Aligning the Camera
		private var lookAtTarget:DisplayObject3D;
		
		/**
		 * Deprecated LocalSpace function
		 * @return LocalSpace
		 */
		public function xxxls ():LocalSpace
		{
			ls.RegenerateOrthonormalBasis2 (Vector3.VectorSubtraction(Target, Position),Up);
			return ls;
		}

		/**
		 * Constructor
		 */
		public function PSCamera ()
		{
			PV3DCamera = new Camera3D();
			PV3DCamera.focus = 30;
			PV3DCamera.zoom = -20;
			PV3DCamera.update(Demo.viewport.sizeRectangle);
			lookAtTarget = new DisplayObject3D();
			Reset ();
		}

		/**
		 * Reset all camera state to default values
		 */ 
		public function Reset ():void
		{
			// reset camera's position and orientation
			ResetLocalSpace ();

			ls=new LocalSpace();

			// "look at" point, center of view
			Target=Vector3.Zero;

			// vehicle being tracked
			VehicleToTrack=null;

			// aim at predicted position of vehicleToTrack, this far into thefuture
			AimLeadTime=1.0;

			// make first update abrupt
			smoothNextMove=false;

			// relative rate at which camera transitions proceed
			smoothMoveSpeed=1.5;

			// select camera aiming mode
			Mode=CameraMode.Fixed;

			// "constant distance from vehicle" camera mode parameters
			FixedDistanceDistance=1.0;
			FixedDistanceVerticalOffset=0.0;

			// "look straight down at vehicle" camera mode parameters
			LookDownDistance=30.0;

			// "static" camera mode parameters
			FixedPosition=new Vector3(75,75,75);
			FixedTarget=Vector3.Zero;
			FixedUp=Vector3.Up;

			// "fixed local offset" camera mode parameters
			FixedLocalOffset=new Vector3(5,5,-5);

			// "offset POV" camera mode parameters
			PovOffset = new Vector3(0, 1, -3);
		}

		/**
		 * Per frame simulation update
		 * @param	currentTime Current System time. Taken from the Realtime OpenSteer Clock
		 * @param	elapsedTime	Time elasped since the start of the last clock update.
		 * @param	simulationPaused Flag that checks if the clock is paused.
		 */ 
		public function Update (currentTime:Number,elapsedTime:Number,simulationPaused:Boolean):void
		{
			// vehicle being tracked (just a reference with a more concise name)
			var v:IVehicle=VehicleToTrack;
			var noVehicle:Boolean=VehicleToTrack == null;

			// new position/target/up, set in switch below, defaults to current
			var newPosition:Vector3=Position;
			var newTarget:Vector3=Target;
			var newUp:Vector3=Up;

			// prediction time to compensate for lag caused by smoothing moves
			var antiLagTime:Number=simulationPaused?0.0:1.0 / smoothMoveSpeed;

			// aim at a predicted future position of the target vehicle
			var predictionTime:Number=AimLeadTime + antiLagTime+0.0;

			// set new position/target/up according to camera aim mode
			switch (Mode)
			{
				case CameraMode.Fixed :
					newPosition=FixedPosition;
					newTarget=FixedTarget;
					newUp=FixedUp;
					break;

				case CameraMode.FixedDistanceOffset :
					if (noVehicle)
					{
						break;
					}
					newUp=Vector3.Up;// xxx maybe this should be v.up ?
					newTarget=v.PredictFuturePosition(predictionTime);
					newPosition=ConstantDistanceHelper(elapsedTime);
					break;

				case CameraMode.StraightDown :
					if (noVehicle)
					{
						break;
					}
					newUp=v.Forward;
					newTarget=v.PredictFuturePosition(predictionTime);
					newPosition=newTarget;
					newPosition.y+= LookDownDistance;
					break;

				case CameraMode.FixedLocalOffset :
					if (noVehicle)
					{
						break;
					}
					newUp=v.Up;
					newTarget=v.PredictFuturePosition(predictionTime);
					newPosition=v.GlobalizePosition(FixedLocalOffset);
					break;

				case CameraMode.OffsetPOV :
					{
						if (noVehicle)
						{
							break;
						}
						newUp=v.Up;
						var futurePosition:Vector3=v.PredictFuturePosition(antiLagTime);
						var globalOffset:Vector3=v.GlobalizeDirection(PovOffset);
						newPosition=Vector3.VectorAddition(futurePosition, globalOffset);
						// XXX hack to improve smoothing between modes (no effect on aim)
						var L:Number=10.0;
						newTarget=Vector3.VectorAddition(newPosition,Vector3.ScalarMultiplication(L, v.Forward));
						break;

					}
				default :
					break;
			}

			// blend from current position/target/up towards new values
			SmoothCameraMove (newPosition,newTarget,newUp,elapsedTime);

			//HACK: Hijack OpenSteer Camera to fix for PV3D display
			if(SimpleVehicle(VehicleToTrack).VehicleMesh)
			{
				drawCameraLookAtCheck(Position, Target, Up);
				if (Mode == CameraMode.StraightDown)
				{
					var tempPos:Number3D = Position.ToNumber3D();
					tempPos.y = 1;
					lookAtTarget.position = tempPos;
					PV3DCamera.lookAt(lookAtTarget,Up.ToNumber3D());
				}
				else
				{
					lookAtTarget.position = Target.ToNumber3D();
					PV3DCamera.lookAt(lookAtTarget, Up.ToNumber3D());
				}
			}
		}
		
		/**
		 * Checks for a degenerate camera Position
		 * @param	cameraPosition The current Camera Position
		 * @param	pointToLookAt The point at which the Camera is to look
		 * @param	up The Up vector (Could be Vehicle or Stable)
		 */
		public function drawCameraLookAtCheck (cameraPosition:Vector3,pointToLookAt:Vector3,up:Vector3):void
		{
			const view:Vector3 = Vector3.VectorSubtraction(pointToLookAt, cameraPosition);
			const perp:Vector3 = view.PerpendicularComponent(up);
			if (Vector3.isEqual(perp,Vector3.Zero))
				trace("OpenSteer - LookAt: degenerate camera");
		}

		/**
		 * Helper function that helps override the Update method.
		 * @param	currentTime Current System time. Taken from the Realtime OpenSteer Clock
		 * @param	elapsedTime Time elasped since the start of the last clock update.
		 */
		public function callUpdate (currentTime:Number,elapsedTime:Number):void
		{
			Update (currentTime,elapsedTime,false);
		}

		/**
		 * Helper function for "drag behind" mode
		 * @param	elapsedTime Time elasped since the start of the last clock update.
		 * @return
		 */ 
		protected function ConstantDistanceHelper (elapsedTime:Number):Vector3
		{
			// is the "global up"/"vertical" offset constraint enabled?  (it forces
			// the camera's global-up (Y) cordinate to be a above/below the target
			// vehicle by a given offset.)
			var constrainUp:Boolean=(FixedDistanceVerticalOffset != 0);

			// vector offset from target to current camera position
			var adjustedPosition:Vector3=new Vector3(Position.x,constrainUp?Target.y:Position.y,Position.z);
			var offset:Vector3=Vector3.VectorSubtraction(adjustedPosition,Target);

			// current distance between them
			var distance:Number=offset.Magnitude();

			// move camera only when geometry is well-defined (avoid degenerate case)
			if (distance == 0)
			{
				return Position;
			}
			else
			{
				// unit vector along original offset
				var unitOffset:Vector3=Vector3.ScalarMultiplication(1/distance,offset);

				// new offset of length XXX
				//var xxxDistance:Number = Number(Math.Sqrt(Utilities.Square(FixedDistanceDistance) - Utilities.Square(FixedDistanceVerticalOffset)));
				var xxxDistance:Number=Number(Math.sqrt((FixedDistanceDistance * FixedDistanceDistance) - (FixedDistanceVerticalOffset * FixedDistanceVerticalOffset)))+0.0;
				var newOffset:Vector3=Vector3.ScalarMultiplication(xxxDistance,unitOffset);

				// return new camera position: adjust distance to target
				return Vector3.VectorAddition(Vector3.VectorAddition(Target, newOffset), new Vector3(0,FixedDistanceVerticalOffset,0));
			}
		}

		/**
		 * Smoothly move camera ...
		 * @param	newPosition The Position to Smoothly move the camera to
		 * @param	newTarget The new Target to look at
		 * @param	newUp The Up Vector required to align the camera
		 * @param	elapsedTime Time elasped since the start of the last clock update.
		 */ 
		public function SmoothCameraMove (newPosition:Vector3,newTarget:Vector3,newUp:Vector3,elapsedTime:Number):void
		{
			if (smoothNextMove)
			{
				var smoothRate:Number=(elapsedTime * smoothMoveSpeed)+0.0;

				var tempPosition:Vector3=Position;
				var tempUp:Vector3=Up;
				tempPosition = Utilities.BlendIntoAccumulator2 (smoothRate,newPosition,tempPosition);
				Target = Utilities.BlendIntoAccumulator2 (smoothRate,newTarget,Target);
				tempUp = Utilities.BlendIntoAccumulator2 (smoothRate,newUp,tempUp);
				Position = tempPosition;
				Up=tempUp;
				
				// xxx not sure if these are needed, seems like a good idea
				// xxx (also if either up or oldUP are zero, use the other?)
				// xxx (even better: force up to be perp to target-position axis))
				if (Vector3.isEqual(Up,Vector3.Zero))
				{
					Up=Vector3.Up;
				
				}
				else
				{
					Up.Normalize();
				}
			}
			else
			{
				smoothNextMove=true;
				Position = newPosition;
				Target = newTarget;
				Up=newUp;
			}
			if(SimpleVehicle(VehicleToTrack).VehicleMesh)
			{
				PV3DCamera.position = Position.ToNumber3D();
			}
		}

		public function DoNotSmoothNextMove():void
		{
			smoothNextMove=false;
		}

		/**
		 * Adjust the offset vector of the current camera mode based on a
		 * "mouse adjustment vector" from OpenSteerDemo (xxx experiment 10-17-02)
		 * @param	adjustment
		 */
		public function MouseAdjustOffset (adjustment:Vector3):void
		{
			// vehicle being tracked (just a reference with a more concise name)
			var v:IVehicle=VehicleToTrack;

			switch (Mode)
			{
				case CameraMode.Fixed :
					{
						var offset:Vector3=Vector3.VectorSubtraction(FixedPosition,FixedTarget);
						var adjusted:Vector3=MouseAdjustPolar(adjustment,offset);
						FixedPosition=Vector3.VectorAddition(FixedTarget, adjusted);
						break;

					}
				case CameraMode.FixedDistanceOffset :
					{
						// XXX this is the oddball case, adjusting "position" instead
						// XXX of mode parameters, hence no smoothing during adjustment
						// XXX Plus the fixedDistVOffset feature complicates things
						offset=Vector3.VectorSubtraction(Position , Target);
						adjusted=MouseAdjustPolar(adjustment,offset);
						// XXX --------------------------------------------------
						//position = target + adjusted;
						//fixedDistDistance = adjusted.length();
						//fixedDistVOffset = position.y - target.y;
						// XXX --------------------------------------------------
						//const float s = smoothMoveSpeed * (1.0f/40f);
						//const Vector3 newPosition = target + adjusted;
						//position = interpolate (s, position, newPosition);
						//fixedDistDistance = interpolate (s, fixedDistDistance, adjusted.length());
						//fixedDistVOffset = interpolate (s, fixedDistVOffset, position.y - target.y);
						// XXX --------------------------------------------------
						//position = target + adjusted;
						Position = Vector3.VectorAddition(Target , adjusted);
						FixedDistanceDistance=adjusted.Magnitude();
						//fixedDistVOffset = position.y - target.y;
						FixedDistanceVerticalOffset=Position.y - Target.y;
						// XXX --------------------------------------------------
						break;

					}
				case CameraMode.StraightDown :
					{
						offset=new Vector3(0,0,LookDownDistance);
						adjusted=MouseAdjustPolar(adjustment,offset);
						LookDownDistance=adjusted.z;
						break;

					}
				case CameraMode.FixedLocalOffset :
					{
						offset=v.GlobalizeDirection(FixedLocalOffset);
						adjusted=MouseAdjustPolar(adjustment,offset);
						FixedLocalOffset=v.LocalizeDirection(adjusted);
						break;

					}
				case CameraMode.OffsetPOV :
					{
						// XXX this might work better as a translation control, it is
						// XXX non-obvious using a polar adjustment when the view
						// XXX center is not at the camera aim target
						offset=v.GlobalizeDirection(PovOffset);
						adjusted=MouseAdjustOrtho(adjustment,offset);
						PovOffset=v.LocalizeDirection(adjusted);
						break;

					}
				default :
					break;
			}
		}

		/**
		 * Adjust the Camera to a Polar Offset
		 * @param	polar Boolen flag that tells whether the adjustments is polar or not.
		 * @param	adjustment The Adjustment vector
		 * @param	offsetToAdjust The Offset for the adjustment
		 * @return
		 */
		public function MouseAdjust2 (polar:Boolean,adjustment:Vector3,offsetToAdjust:Vector3):Vector3
		{
			// value to be returned
			var result:Vector3=offsetToAdjust;

			// using the camera's side/up axes (essentially: screen space) move the
			// offset vector sideways according to adjustment.x and vertically
			// according to adjustment.y, constrain the offset vector's length to
			// stay the same, hence the offset's "tip" stays on the surface of a
			// sphere.
			var oldLength:Number=result.Magnitude();
			var rate:Number = polar?oldLength:1.0;
			result = Vector3.VectorAddition(result,Vector3.ScalarMultiplication((adjustment.x * rate),xxxls().Side));
			result = Vector3.VectorAddition(result,Vector3.ScalarMultiplication((adjustment.y * rate),xxxls().Up));
			if (polar)
			{
				var newLength:Number=result.Magnitude();
				result = Vector3.ScalarMultiplication((oldLength / newLength),result);
			}

			// change the length of the offset vector according to adjustment.z
			if (polar)
			{
				result = Vector3.ScalarMultiplication(1 + adjustment.z,result);
			}
			else
			{
				result = Vector3.VectorAddition(result,Vector3.ScalarMultiplication(adjustment.z,xxxls().Forward));

			}
			return result;
		}

		/**
		 * Polar Camera Adjustment
		 * @param	adjustment
		 * @param	offsetToAdjust
		 * @return
		 */
		public function MouseAdjustPolar (adjustment:Vector3,offsetToAdjust:Vector3):Vector3
		{
			return MouseAdjust2(true,adjustment,offsetToAdjust);
		}
		
		/**
		 * Orthographic Camera Adjustment
		 * @param	adjustment
		 * @param	offsetToAdjust
		 * @return
		 */
		public function MouseAdjustOrtho (adjustment:Vector3,offsetToAdjust:Vector3):Vector3
		{
			return MouseAdjust2(false,adjustment,offsetToAdjust);
		}

		/**
		 * String naming current camera mode, used by OpenSteerDemo
		 */ 
		public function get ModeName ():String
		{
			switch (Mode)
			{
				case CameraMode.Fixed :
					return "Static";
				case CameraMode.FixedDistanceOffset :
					return "Fixed Distance Offset";
				case CameraMode.FixedLocalOffset :
					return "Fixed Local Offset";
				case CameraMode.OffsetPOV :
					return "Offset POV";
				case CameraMode.StraightDown :
					return "Straight Down";
				default :
					return "Unknown";
			}
		}

		/**
		 * Select next camera mode, used by OpenSteerDemo
		 */ 
		public function SelectNextMode ():void
		{
			Mode=SuccessorMode(Mode);
			if (Mode >= CameraMode.EndMode)
			{
				Mode=SuccessorMode(CameraMode.StartMode);
			}
		}

		/**
		 * The mode that comes after the given mode (used by selectNextMode)
		 */ 
		protected function SuccessorMode (cm:int):int
		{
			return (cm + 1);
		}
	}
}