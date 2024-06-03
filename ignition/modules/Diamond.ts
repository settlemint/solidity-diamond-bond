import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const DiamondModule = buildModule('DiamondModule', (m) => {
  const facetNames = ['DiamondLoupeFacet', 'ERC1155Facet', 'BondFacet'];
  const facets = facetNames.map((facetName) => m.contract(facetName));
  const selectors = [
    ['0x7a0ed627', '0xcdffacc6', '0xadfca15e', '0x52ef6b2c'],
    ['0x156e29f6', '0xf5298aca', '0x01a69546', '0x00fdd58e', '0xf242432a'],
    [
      '0x60332e89',
      '0x796b89ec',
      '0x9226537e',
      '0x40e58ee5',
      '0x68aea41b',
      '0x2dcb118e',
      '0xee5b280a',
      '0xa8314de7',
      '0xc89fa570',
      '0x906b131a',
      '0xde99347a',
      '0x43a19a65',
      '0x25830db3',
      '0xf9765634',
      '0x22e29d59',
      '0x8dea1f47',
      '0xe3adc7ee',
      '0x7a828b28',
      '0xf844a31c',
    ],
  ];

  const diamondInit = m.contract('DiamondInit');

  const genericToken = m.contract('GenericToken', ['GenericToken', 'GEN']);

  const diamond = m.contract('Diamond', [
    [
      [facets[0], 0, selectors[0]],
      [facets[1], 0, selectors[1]],
      [facets[2], 0, selectors[2]],
    ],
    [m.getAccount(0), diamondInit, '0xe1c7392a'],
  ]);

  return { diamondInit, genericToken, facets };
  //return { genericToken };
});
export default DiamondModule;
