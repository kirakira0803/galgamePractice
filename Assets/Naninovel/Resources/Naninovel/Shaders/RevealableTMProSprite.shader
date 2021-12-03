// Copyright 2017-2021 Elringus (Artyom Sovetnikov). All rights reserved.

Shader "Naninovel/RevealableTMProSprite"
{
	Properties
	{
		_MainTex ("Sprite Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)
		
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255

		_ColorMask ("Color Mask", Float) = 15
		_ClipRect ("Clip Rect", vector) = (-32767, -32767, 32767, 32767)

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
		
		// -------------- Naninovel font. --------------
		_LineClipRect("Lines Clip Rect", Vector) = (0,0,0,0)
		_CharClipRect("Characters Clip Rect", Vector) = (0,0,0,0)
		_CharFadeWidth("Characters Fade Width", Float) = 0
		_CharSlantAngle("Characters Slate Angle", Float) = 0
		// ---------------------------------------------
	}

	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}
		
		Stencil
		{
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp] 
			ReadMask [_StencilReadMask]
			WriteMask [_StencilWriteMask]
		}

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest [unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask [_ColorMask]

		Pass
		{
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			#pragma multi_compile __ UNITY_UI_CLIP_RECT
			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			
			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color    : COLOR;
				half2 texcoord  : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
			};
			
			fixed4 _Color;
			fixed4 _TextureSampleAdd;
			float4 _ClipRect;

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				OUT.worldPosition = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

				OUT.texcoord = IN.texcoord;
				
				#ifdef UNITY_HALF_TEXEL_OFFSET
				OUT.vertex.xy += (_ScreenParams.zw-1.0)*float2(-1,1);
				#endif
				
				OUT.color = IN.color * _Color;
				return OUT;
			}

			sampler2D _MainTex;

	        // -------------- Naninovel font. --------------
	        float4 _LineClipRect, _CharClipRect;
	        float _CharFadeWidth, _CharSlantAngle;
	        inline float IsPositionOutsideRect(in float2 position, in float4 rect)
	        {
	            float2 isInside = step(rect.xy, position.xy) * step(position.xy, rect.zw);
	            return 1.0 - isInside.x * isInside.y;
	        }
	        // ---------------------------------------------
		

			fixed4 frag(v2f IN) : SV_Target
			{
				half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * IN.color;
				
				#if UNITY_UI_CLIP_RECT
					color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
				#endif

				// -------------- Naninovel font. --------------
		        // Hide unrevealed (not-printed-yet) text lines.
		        color *= IsPositionOutsideRect(IN.worldPosition.xy, _LineClipRect);
		        // Apply gradient fade to the current line.
		        if (IN.worldPosition.y < _CharClipRect.w)
		        {
		            static const float PI = 3.14159;
		            float alpha = PI / 2.0 - radians(_CharSlantAngle);
		            float distance = (_CharClipRect.x - IN.worldPosition.x) + (IN.worldPosition.y - _CharClipRect.y) / tan(alpha);
		            color *= saturate(distance / _CharFadeWidth);
		        }
		        // ---------------------------------------------

				#ifdef UNITY_UI_ALPHACLIP
					clip (color.a - 0.001);
				#endif

				return color;
			}
		ENDCG
		}
	}
}
