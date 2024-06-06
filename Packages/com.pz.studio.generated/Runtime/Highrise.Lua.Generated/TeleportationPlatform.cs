/*

    Copyright (c) 2024 Pocketz World. All rights reserved.

    This is a generated file, do not edit!

    Generated by com.pz.studio
*/

#if UNITY_EDITOR

using System;
using System.Linq;
using UnityEngine;
using Highrise.Client;

namespace Highrise.Lua.Generated
{
    [AddComponentMenu("Lua/TeleportationPlatform")]
    [LuaBehaviourScript(s_scriptGUID)]
    public class TeleportationPlatform : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "a7c1a0f0a021d6146950c7455f67e5fe";
        public override string ScriptGUID => s_scriptGUID;

        [SerializeField] public System.String m_type = "";

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), m_type),
            };
        }
    }
}

#endif
