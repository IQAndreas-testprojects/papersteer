﻿// ----------------------------------------------------------------------------
//
// OpenSteer - Action Script 3 Port
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

package tabinda.as3steer
{
	/**
	 *  Pathway: a pure virtual base class for an abstract pathway in space, as for
     *  example would be used in path following.
	 */
	public class Pathway
	{
		// Given an arbitrary point ("A"), returns the nearest point ("P") on
		// this path.  Also returns, via output arguments, the path tangent at
		// P and a measure of how far A is outside the Pathway's "tube".  Note
		// that a negative distance indicates A is inside the Pathway.
		public function mapPointToPath(point:Vector3,tStruct:mapReturnStruct):Vector3
		{
			return Vector3.ZERO;
		}

		// given a distance along the path, convert it to a point on the path
		public function mapPathDistanceToPoint(pathDistance:Number):Vector3
		{
			return Vector3.ZERO;
		}

		// Given an arbitrary point, convert it to a distance along the path.
		public function mapPointToPathDistance(point:Vector3):Number
		{
			return 0;
		}

		// is the given point inside the path tube?
		public function isInsidePath(point:Vector3):Boolean
		{
			var tStruct:mapReturnStruct=new mapReturnStruct();

			mapPointToPath(point,tStruct);//tangent, outside);
			return tStruct.outside < 0;
		}

		// how far outside path tube is the given point?  (negative is inside)
		public function howFarOutsidePath(point:Vector3):Number
		{
			var tStruct:mapReturnStruct=new mapReturnStruct  ;

			mapPointToPath(point,tStruct);
			return tStruct.outside;
		}
	}
}